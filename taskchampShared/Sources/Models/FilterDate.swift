import Foundation

// MARK: - FilterDateAttribute

/// Task date attributes that can be compared in a filter, e.g. `end.after:now-1wk`.
public enum FilterDateAttribute: String, CaseIterable {
    case due
    case scheduled
    case until
    case modified
    case end
    case entry

    func value(of task: TCTask) -> Date? {
        switch self {
        case .due: return task.due
        case .scheduled: return task.scheduled
        case .until: return task.until
        case .modified: return task.modified
        case .end: return task.end
        case .entry: return task.entry
        }
    }
}

// MARK: - FilterDateComparison

public enum FilterDateComparison: String {
    case after
    case before

    /// Taskwarrior accepts `above`/`below` as aliases for `after`/`before`.
    init?(modifier: String) {
        switch modifier.lowercased() {
        case "after", "above": self = .after
        case "before", "below": self = .before
        default: return nil
        }
    }
}

// MARK: - FilterDate

/// A Taskwarrior-style date value such as `now`, `today`, `2026-09-01`, `now-1wk` or `-3d`.
/// Relative values are resolved when the filter is evaluated, so saved filters keep rolling.
public struct FilterDate: Equatable {
    enum Anchor: Equatable {
        case now
        case startOfDay(dayOffset: Int)
        case endOfDay
        case startOfWeek
        case startOfMonth
        case startOfYear
        case absolute(Date)
    }

    let anchor: Anchor
    let offset: DateComponents?
    /// The value as written, used for compact descriptions.
    public let text: String

    public init?(_ text: String) {
        let lowered = text.lowercased()
        guard !lowered.isEmpty else { return nil }

        // Split "<anchor><+|-><duration>"; a leading sign means "relative to now".
        var anchorPart = lowered
        var offsetPart = ""
        // ISO dates contain dashes too, so pick the first sign whose prefix is a valid anchor.
        let signIndices = lowered.indices.dropFirst().filter { lowered[$0] == "+" || lowered[$0] == "-" }
        if let signIndex = signIndices.first(where: { Self.anchor(from: String(lowered[..<$0])) != nil }) {
            anchorPart = String(lowered[..<signIndex])
            offsetPart = String(lowered[signIndex...])
        } else if lowered.hasPrefix("+") || lowered.hasPrefix("-") {
            anchorPart = "now"
            offsetPart = lowered
        }

        guard let anchor = Self.anchor(from: anchorPart) else { return nil }
        self.anchor = anchor
        self.text = text

        if offsetPart.isEmpty {
            offset = nil
        } else {
            guard let offset = Self.offset(from: offsetPart) else { return nil }
            self.offset = offset
        }
    }

    public func resolve(now: Date = Date(), calendar: Calendar = .current) -> Date {
        let base = resolveAnchor(now: now, calendar: calendar)
        guard let offset else { return base }
        return calendar.date(byAdding: offset, to: base) ?? base
    }

    private func resolveAnchor(now: Date, calendar: Calendar) -> Date {
        switch anchor {
        case .now:
            return now
        case .startOfDay(let dayOffset):
            let start = calendar.startOfDay(for: now)
            return calendar.date(byAdding: .day, value: dayOffset, to: start) ?? start
        case .endOfDay:
            let start = calendar.startOfDay(for: now)
            let nextDay = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            return nextDay.addingTimeInterval(-1)
        case .startOfWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        case .startOfMonth:
            return calendar.dateInterval(of: .month, for: now)?.start ?? now
        case .startOfYear:
            return calendar.dateInterval(of: .year, for: now)?.start ?? now
        case .absolute(let date):
            return date
        }
    }

    private static func anchor(from text: String) -> Anchor? {
        switch text {
        case "now": return .now
        case "today", "sod": return .startOfDay(dayOffset: 0)
        case "yesterday": return .startOfDay(dayOffset: -1)
        case "tomorrow": return .startOfDay(dayOffset: 1)
        case "eod": return .endOfDay
        case "sow": return .startOfWeek
        case "som": return .startOfMonth
        case "soy": return .startOfYear
        default: return absoluteDate(from: text).map { .absolute($0) }
        }
    }

    /// `YYYY-MM-DD` (local midnight) or `YYYY-MM-DDTHH:MM[:SS]` (local time).
    private static func absoluteDate(from text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .current
        for format in ["yyyy-MM-dd", "yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd'T'HH:mm:ss"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: text) {
                return date
            }
        }
        return nil
    }

    /// Parses a signed Taskwarrior duration such as `-1wk`, `+3d`, `-2mo`, `-90min`.
    /// As in Taskwarrior, `m`/`min` are minutes and `mo` is months.
    private static func offset(from text: String) -> DateComponents? {
        guard let sign = text.first, sign == "+" || sign == "-" else { return nil }
        let body = text.dropFirst()
        let digits = body.prefix { $0.isNumber }
        let unit = String(body.dropFirst(digits.count))
        let amount = (digits.isEmpty ? 1 : Int(digits) ?? 0) * (sign == "-" ? -1 : 1)

        var components = DateComponents()
        switch unit {
        case "s", "sec", "secs", "second", "seconds":
            components.second = amount
        case "m", "min", "mins", "minute", "minutes":
            components.minute = amount
        case "h", "hr", "hrs", "hour", "hours":
            components.hour = amount
        case "d", "day", "days":
            components.day = amount
        case "w", "wk", "wks", "week", "weeks":
            components.day = amount * 7
        case "mo", "mos", "mth", "mths", "month", "months":
            components.month = amount
        case "q", "qtr", "qtrs", "quarter", "quarters":
            components.month = amount * 3
        case "y", "yr", "yrs", "year", "years":
            components.year = amount
        default:
            return nil
        }
        return components
    }
}
