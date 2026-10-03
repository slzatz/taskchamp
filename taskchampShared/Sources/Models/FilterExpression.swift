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
        case .and(let expressions):
            return expressions.allSatisfy { $0.matches(task, now: now) }
        case .or(let expressions):
            return expressions.contains { $0.matches(task, now: now) }
        case .tag(let name):
            return task.tags?.contains { $0.name == name } ?? false
        case .notTag(let name):
            return !(task.tags?.contains { $0.name == name } ?? false)
        case .project(let name):
            return task.project == name
        case .priority(let prio):
            let taskPrio = task.priority ?? .none
            return taskPrio == prio
        case .status(let status):
            return task.status == status
        case .recur:
            return task.recur != nil
        case .date(let attribute, let comparison, let value):
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
        case .and(let expressions):
            return expressions.map { $0.compactDescription(nestedInAnd: true) }.joined(separator: " ")
        case .or(let expressions):
            let joined = expressions.map { $0.compactDescription(nestedInAnd: false) }.joined(separator: " | ")
            return nestedInAnd ? "(\(joined))" : joined
        case .tag(let name):
            return "+\(name)"
        case .notTag(let name):
            return "-\(name)"
        case .project(let name):
            return name
        case .priority(let prio):
            return prio == .none ? "no prio" : prio.rawValue
        case .status(let status):
            return status.rawValue
        case .recur:
            return "recur"
        case .date(let attribute, let comparison, let value):
            return "\(attribute.rawValue)\(comparison == .after ? ">" : "<")\(value.text)"
        }
    }

    func containsStatus(_ status: TCTask.Status) -> Bool {
        switch self {
        case .status(let taskStatus):
            return taskStatus == status
        case .and(let expressions), .or(let expressions):
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
    case priority(String)
    case status(String)
    case recur
    case date(FilterDateAttribute, FilterDateComparison, FilterDate)
}

// MARK: - FilterParser

public enum FilterParser {
    // MARK: - Public API

    public static func parse(_ input: String) -> FilterExpression? {
        let tokens = tokenize(input)
        guard !tokens.isEmpty else { return nil }
        var index = 0
        let result = parseOrExpression(tokens: tokens, index: &index)
        return result
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
            while i < chars.count && !chars[i].isWhitespace && chars[i] != "(" && chars[i] != ")" {
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
            return .priority(String(word.dropFirst("prio:".count)))
        case _ where word.hasPrefix("priority:"):
            return .priority(String(word.dropFirst("priority:".count)))
        case _ where word.hasPrefix("status:"):
            return .status(String(word.dropFirst("status:".count)))
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
            if index < tokens.count && tokens[index] == .rightParen {
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
        case .tag(let name):
            index += 1
            return .tag(name)
        case .notTag(let name):
            index += 1
            return .notTag(name)
        case .project(let value):
            index += 1
            return .project(value)
        case .priority(let value):
            index += 1
            guard let prio = TCTask.Priority(rawValue: value) else { return nil }
            return .priority(prio)
        case .status(let value):
            index += 1
            guard let status = TCTask.Status(rawValue: value) else { return nil }
            return .status(status)
        case .recur:
            index += 1
            return .recur
        case .date(let attribute, let comparison, let value):
            index += 1
            return .date(attribute, comparison, value)
        default:
            return nil
        }
    }
}
