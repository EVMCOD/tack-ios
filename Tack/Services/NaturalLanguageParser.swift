import Foundation

/// Lightweight natural language parser for `QuickAddSheet` and the Siri shortcut.
///
/// Recognized patterns (matched in order):
///  - `#tag1, tag2`     → tags
///  - `!high` / `!med` / `!low` / `!urgent` → priority (currently metadata only)
///  - `today`, `tomorrow`, `next <weekday>`, `in N days|hours|minutes`
///  - `5pm`, `17:30`, `25 dec`
///
/// Examples:
///  - "Buy milk tomorrow 5pm #groceries !high"
///  - "Review PR #work in 3 days"
///  - "Call John next monday"
public struct NaturalLanguageParser {

    public struct Priority: Equatable { let level: Int; let raw: String }

    public struct Output {
        public var cleanTitle: String
        public var dueAt: Date?
        public var tags: [String]
        public var priority: Priority?
    }

    public static func parse(_ input: String, now: Date = .now) -> Output {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Tags
        var tags: [String] = []
        let tagRegex = try! NSRegularExpression(pattern: "#([a-zA-Z0-9_\\-]+)")
        for m in tagRegex.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            guard let r = Range(m.range, in: text), let c = Range(m.range(at: 1), in: text) else { continue }
            tags.append(String(text[c]))
            text.removeSubrange(r)
        }

        // 2. Priority
        var priority: Priority?
        let priMap: [(String, Int)] = [("!low", 0), ("!med", 1), ("!high", 2), ("!urgent", 3)]
        for (token, level) in priMap where text.lowercased().contains(token) {
            priority = Priority(level: level, raw: token)
            text = text.replacingOccurrences(of: token, with: "", options: .caseInsensitive)
            break
        }

        // 3. Due date — try patterns in order, replace matched portion in text.
        var due: Date?
        let lowered = text.lowercased()
        let strippedMatch: (String) -> Void = { matched in
            text = text.replacingOccurrences(of: matched, with: "", options: .caseInsensitive)
            while text.contains("  ") { text = text.replacingOccurrences(of: "  ", with: " ") }
        }

        let cal = Calendar.current

        // today / tomorrow / next <weekday>
        let weekdayMap: [(String, Int)] = [
            ("next monday", 2), ("next tuesday", 3), ("next wednesday", 4),
            ("next thursday", 5), ("next friday", 6), ("next saturday", 7), ("next sunday", 1)
        ]
        if lowered.contains("tomorrow") {
            due = adjustedTomorrow(cal: cal, now: now)
            strippedMatch("tomorrow")
        } else if lowered.contains("today") {
            due = adjustedDate(cal: cal, now: now, hour: 18)
            strippedMatch("today")
        } else if let wMatch = weekdayMap.first(where: { lowered.contains($0.0) }) {
            due = nextWeekday(cal: cal, weekday: wMatch.1, hour: 9, ref: now)
            strippedMatch(wMatch.0)
        }

        // in N (day|hour|minute)s
        if due == nil, let m = matchFirst(in: text, pattern: "in (\\d+) (day|hour|minute)s?") {
            if let n = Int(m.value(for: 1) ?? ""), let unit = m.value(for: 2) {
                let mult: TimeInterval = (unit == "day") ? 86400 : (unit == "hour") ? 3600 : 60
                due = now.addingTimeInterval(TimeInterval(n) * mult)
                strippedMatch(m.original)
            }
        }

        // HH[:MM] [am|pm]
        if due == nil, let m = matchFirst(in: text, pattern: "(\\d{1,2})(:(\\d{2}))?\\s*(am|pm)") {
            let hStr = m.value(for: 1) ?? ""
            guard var hour = Int(hStr) else { _ = 0 as Int; return .init(cleanTitle: text.trimmingCharacters(in: .whitespacesAndNewlines), dueAt: nil, tags: tags, priority: priority) }
            let isPM = (m.value(for: 4) ?? "") == "pm"
            if isPM && hour < 12 { hour += 12 }
            if !isPM && hour == 12 { hour = 0 }
            var c = cal.dateComponents([.year, .month, .day], from: now)
            c.hour = hour
            c.minute = Int(m.value(for: 3) ?? "0") ?? 0
            if let candidate = cal.date(from: c) {
                let final = candidate < now ? candidate.addingTimeInterval(86400) : candidate
                due = final
                strippedMatch(m.original)
            }
        }

        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return Output(
            cleanTitle: clean.isEmpty ? "Untitled" : clean,
            dueAt: due,
            tags: tags,
            priority: priority
        )
    }

    // MARK: - Regex helper

    private struct RegexHit {
        let original: String
        private let groups: [String]
        init(_ original: String, groups: [String]) { self.original = original; self.groups = groups }
        func value(for index: Int) -> String? {
            groups.indices.contains(index) ? groups[index] : nil
        }
    }

    private static func matchFirst(in text: String, pattern: String) -> RegexHit? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let m = re.firstMatch(in: text, range: range) else { return nil }
        var groups: [String] = []
        for i in 0..<m.numberOfRanges {
            if i == 0 {
                if let r = Range(m.range, in: text) { groups.append(String(text[r])) }
                else { groups.append("") }
            } else {
                if let r = Range(m.range(at: i), in: text), r.lowerBound < text.endIndex {
                    groups.append(String(text[r]))
                } else {
                    groups.append("")
                }
            }
        }
        return RegexHit(groups[0], groups: Array(groups.dropFirst()))
    }

    // MARK: - Date helpers

    private static func adjustedDate(cal: Calendar, now: Date, hour: Int) -> Date? {
        var c = cal.dateComponents([.year, .month, .day], from: now)
        c.hour = hour
        c.minute = 0
        return cal.date(from: c)
    }

    private static func adjustedTomorrow(cal: Calendar, now: Date) -> Date? {
        let tomorrow = now.addingTimeInterval(86400)
        var c = cal.dateComponents([.year, .month, .day], from: tomorrow)
        c.hour = 9
        c.minute = 0
        return cal.date(from: c)
    }

    private static func nextWeekday(cal: Calendar, weekday: Int, hour: Int, ref: Date) -> Date? {
        var components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: ref)
        components.weekday = weekday
        components.hour = hour
        components.minute = 0
        if let date = cal.date(from: components), date > ref {
            return date
        }
        components.weekOfYear = (components.weekOfYear ?? 0) + 1
        return cal.date(from: components)
    }
}
