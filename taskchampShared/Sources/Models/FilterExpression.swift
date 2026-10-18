import Foundation

// MARK: - FilterExpression

public indirect enum FilterExpression {
    case and([FilterExpression])
    // swiftlint:disable:next identifier_name
    case or([FilterExpression])
    case tag(String)
    case notTag(String)
    case project(String)
    case priority(TCTask.Priority)
    case status(TCTask.Status)
    case recur
    case date(FilterDateAttribute, FilterDateComparison, FilterDate)

    public func matches(_ task: TCTask, now: Date = Date()) -> Bool {
        switch self {
        case let .and(expressions):
            return expressions.allSatisfy { $0.matches(task, now: now) }
        case let .or(expressions):
            return expressions.contains { $0.matches(task, now: now) }
        case let .tag(name):
            return task.tags?.contains { $0.name == name } ?? false
        case let .notTag(name):
            return !(task.tags?.contains { $0.name == name } ?? false)
        case let .project(name):
            return task.project == name
        case let .priority(prio):
            let taskPrio = task.priority ?? .none
            return taskPrio == prio
        case let .status(status):
            return task.status == status
        case .recur:
            return task.recur != nil
        case let .date(attribute, comparison, value):
            // As in Taskwarrior, a task without the attribute never matches a date comparison.
            guard let taskDate = attribute.value(of: task) else { return false }
            let date = value.resolve(now: now)
            return comparison == .after ? taskDate > date : taskDate < date
        }
    }

    /// Short human-readable form for headers, e.g. `status:pending prio:H project:work` → `pending H work`.
    public var compactDescription: String {
        compactDescription(nestedInAnd: false)
    }

    private func compactDescription(nestedInAnd: Bool) -> String {
        switch self {
        case let .and(expressions):
            return expressions.map { $0.compactDescription(nestedInAnd: true) }.joined(separator: " ")
        case let .or(expressions):
            let joined = expressions.map { $0.compactDescription(nestedInAnd: false) }.joined(separator: " | ")
            return nestedInAnd ? "(\(joined))" : joined
        case let .tag(name):
            return "+\(name)"
        case let .notTag(name):
            return "-\(name)"
        case let .project(name):
            return name
        case let .priority(prio):
            return prio == .none ? "no prio" : prio.rawValue
        case let .status(status):
            return status.rawValue
        case .recur:
            return "recur"
        case let .date(attribute, comparison, value):
            return "\(attribute.rawValue)\(comparison == .after ? ">" : "<")\(value.text)"
        }
    }

    /// The project every matching task must have, e.g. `project:work +urgent` → `work`, or
    /// `(project:work +a) or (project:work +b)` → `work`.
    /// `nil` when the filter allows more than one project (`project:a or project:b`) or none.
    public var requiredProject: String? {
        requiredValue { expression in
            if case let .project(name) = expression, !name.isEmpty {
                return name
            }
            return nil
        }
    }

    /// The priority every matching task must have, by the same rules as `requiredProject`.
    public var requiredPriority: TCTask.Priority? {
        requiredValue { expression in
            if case let .priority(prio) = expression {
                return prio
            }
            return nil
        }
    }

    /// The tags every matching task must have, e.g. `(+a +b) or (+a +c)` → `[a]`.
    public var requiredTags: Set<String> {
        switch self {
        case let .tag(name):
            return [name]
        case let .and(expressions):
            return expressions.reduce(into: Set<String>()) { $0.formUnion($1.requiredTags) }
        case let .or(expressions):
            guard let first = expressions.first else { return [] }
            return expressions.dropFirst().reduce(first.requiredTags) { $0.intersection($1.requiredTags) }
        default:
            return []
        }
    }

    /// The one value `atom` reads from the filter's terms that every matching task must share.
    /// `nil` when an `and` holds two different values or an `or` branch allows another.
    private func requiredValue<Value: Hashable>(_ atom: (FilterExpression) -> Value?) -> Value? {
        let values = Set(requiredValues(atom))
        return values.count == 1 ? values.first : nil
    }

    private func requiredValues<Value: Hashable>(_ atom: (FilterExpression) -> Value?) -> [Value] {
        switch self {
        case let .and(expressions):
            return expressions.flatMap { $0.requiredValues(atom) }
        case let .or(expressions):
            // Only a value that every branch requires.
            let branches = expressions.map { $0.requiredValue(atom) }
            guard let first = branches.compactMap({ $0 }).first, branches.allSatisfy({ $0 == first }) else {
                return []
            }
            return [first]
        default:
            return atom(self).map { [$0] } ?? []
        }
    }

    func containsStatus(_ status: TCTask.Status) -> Bool {
        switch self {
        case let .status(taskStatus):
            return taskStatus == status
        case let .and(expressions), let .or(expressions):
            return expressions.contains { $0.containsStatus(status) }
        default:
            return false
        }
    }
}

// MARK: - FilterToken

enum FilterToken: Equatable {
    case leftParen
    case rightParen
    case orKeyword
    case andKeyword
    case tag(String)
    case notTag(String)
    case project(String)
    case priority(TCTask.Priority)
    case status(TCTask.Status)
    case recur
    case date(FilterDateAttribute, FilterDateComparison, FilterDate)
}

// MARK: - FilterParser

public enum FilterParser {
    public static func parse(_ input: String) -> FilterExpression? {
        let tokens = tokenize(input)
        guard !tokens.isEmpty else { return nil }
        var index = 0
        return parseOrExpression(tokens: tokens, index: &index)
    }

    // MARK: - Tokenizer

    static func tokenize(_ input: String) -> [FilterToken] {
        words(in: input).compactMap { token(for: $0) }
    }

    /// Words in `input` that the filter language doesn't understand and would otherwise be
    /// silently ignored (e.g. `due:today` or a misspelled keyword).
    public static func unrecognizedTerms(in input: String) -> [String] {
        words(in: input).filter { token(for: $0) == nil }
    }

    /// Splits `input` into parentheses and whitespace-separated words. A leading `task`
    /// (from a pasted Taskwarrior command line) is dropped.
    private static func words(in input: String) -> [String] {
        var words: [String] = []
        let chars = Array(input)
        var i = 0

        while i < chars.count {
            if chars[i].isWhitespace {
                i += 1
                continue
            }

            if chars[i] == "(" || chars[i] == ")" {
                words.append(String(chars[i]))
                i += 1
                continue
            }

            var word = ""
            while i < chars.count, !chars[i].isWhitespace, chars[i] != "(", chars[i] != ")" {
                word.append(chars[i])
                i += 1
            }
            words.append(word)
        }

        if words.first?.lowercased() == "task" {
            words.removeFirst()
        }
        return words
    }

    private static func token(for word: String) -> FilterToken? {
        switch word {
        case "(":
            return .leftParen
        case ")":
            return .rightParen
        case _ where word.lowercased() == "or":
            return .orKeyword
        case _ where word.lowercased() == "and":
            return .andKeyword
        case _ where word.hasPrefix("project:"):
            return .project(String(word.dropFirst("project:".count)))
        case _ where word.hasPrefix("prio:"):
            return priority(from: String(word.dropFirst("prio:".count))).map { .priority($0) }
        case _ where word.hasPrefix("priority:"):
            return priority(from: String(word.dropFirst("priority:".count))).map { .priority($0) }
        case _ where word.hasPrefix("status:"):
            return TCTask.Status(rawValue: word.dropFirst("status:".count).lowercased()).map { .status($0) }
        case _ where word.lowercased() == "recur":
            return .recur
        case _ where word.hasPrefix("+"):
            let value = String(word.dropFirst())
            return value.isEmpty ? nil : .tag(value)
        case _ where word.hasPrefix("-"):
            let value = String(word.dropFirst())
            return value.isEmpty ? nil : .notTag(value)
        default:
            return dateToken(for: word)
        }
    }

    /// `H`, `M`, `L`, or no priority: `None`, or an empty value as in Taskwarrior's `priority:`.
    private static func priority(from value: String) -> TCTask.Priority? {
        if value.isEmpty || value.lowercased() == "none" {
            return TCTask.Priority.none
        }
        return TCTask.Priority(rawValue: value.uppercased())
    }

    /// `<attribute>.<after|before|above|below>:<date>`, e.g. `end.after:now-1wk`.
    private static func dateToken(for word: String) -> FilterToken? {
        guard let colon = word.firstIndex(of: ":") else { return nil }
        let parts = word[..<colon].split(separator: ".", omittingEmptySubsequences: false)
        guard
            parts.count == 2,
            let attribute = FilterDateAttribute(rawValue: parts[0].lowercased()),
            let comparison = FilterDateComparison(modifier: String(parts[1])),
            let date = FilterDate(String(word[word.index(after: colon)...]))
        else {
            return nil
        }
        return .date(attribute, comparison, date)
    }

    // MARK: - Recursive Descent Parser

    //
    // Grammar:
    //   expression = or_expr
    //   or_expr    = and_expr ("or" and_expr)*
    //   and_expr   = primary ("and"? primary)*
    //   primary    = "(" expression ")" | atom
    //   atom       = tag | notTag | project | priority | status | recur | date

    private static func parseOrExpression(tokens: [FilterToken], index: inout Int) -> FilterExpression? {
        guard let first = parseAndExpression(tokens: tokens, index: &index) else { return nil }

        var operands = [first]
        while index < tokens.count && tokens[index] == .orKeyword {
            index += 1
            guard let next = parseAndExpression(tokens: tokens, index: &index) else { break }
            operands.append(next)
        }

        return operands.count == 1 ? operands[0] : .or(operands)
    }

    private static func parseAndExpression(tokens: [FilterToken], index: inout Int) -> FilterExpression? {
        guard let first = parsePrimary(tokens: tokens, index: &index) else { return nil }

        var operands = [first]
        while index < tokens.count && tokens[index] != .orKeyword && tokens[index] != .rightParen {
            if tokens[index] == .andKeyword {
                index += 1
            }
            guard let next = parsePrimary(tokens: tokens, index: &index) else { break }
            operands.append(next)
        }

        return operands.count == 1 ? operands[0] : .and(operands)
    }

    private static func parsePrimary(tokens: [FilterToken], index: inout Int) -> FilterExpression? {
        guard index < tokens.count else { return nil }

        if tokens[index] == .leftParen {
            index += 1
            guard let expr = parseOrExpression(tokens: tokens, index: &index) else { return nil }
            if index < tokens.count, tokens[index] == .rightParen {
                index += 1
            }
            return expr
        }

        return parseAtom(tokens: tokens, index: &index)
    }

    private static func parseAtom(tokens: [FilterToken], index: inout Int) -> FilterExpression? {
        guard index < tokens.count else { return nil }

        let token = tokens[index]

        switch token {
        case let .tag(name):
            index += 1
            return .tag(name)
        case let .notTag(name):
            index += 1
            return .notTag(name)
        case let .project(value):
            index += 1
            return .project(value)
        case let .priority(prio):
            index += 1
            return .priority(prio)
        case let .status(status):
            index += 1
            return .status(status)
        case .recur:
            index += 1
            return .recur
        case let .date(attribute, comparison, value):
            index += 1
            return .date(attribute, comparison, value)
        default:
            return nil
        }
    }
}
