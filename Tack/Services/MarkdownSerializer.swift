import Foundation

/// Serializes `TaskItem` <-> markdown with YAML frontmatter. Used by the Obsidian adapter.
///
/// File shape:
/// ```
/// ---
/// id: <uuid>
/// title: Buy milk
/// status: open
/// created: 2026-09-08T16:01:00Z
/// due: 2026-09-09T09:00:00Z
/// tags: [groceries, urgent]
/// list: Personal
/// source: tack
/// tackID: <uuid>     # always present so we can re-link after vault moves
/// ---
/// # Buy milk
///
/// Body / notes go here, markdown flavored.
/// ```
public enum MarkdownSerializer {

    private static let dateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    public static func markdown(for task: TaskItem) -> String {
        var frontmatter = "---\n"
        frontmatter += "id: \(task.id.uuidString)\n"
        frontmatter += "title: \(yamlEscape(task.title))\n"
        frontmatter += "status: \(task.status.rawValue)\n"
        frontmatter += "created: \(dateFormatter.string(from: task.createdAt))\n"
        if let due = task.dueAt {
            frontmatter += "due: \(dateFormatter.string(from: due))\n"
        }
        if !task.tags.isEmpty {
            let names = task.tags.map { yamlEscape($0.name) }.joined(separator: ", ")
            frontmatter += "tags: [\(names)]\n"
        }
        frontmatter += "list: \(yamlEscape(task.listName))\n"
        frontmatter += "source: tack\n"
        frontmatter += "tackID: \(task.id.uuidString)\n"
        frontmatter += "---\n\n"
        frontmatter += "# \(task.title)\n\n"
        if !task.notes.isEmpty {
            frontmatter += task.notes + "\n"
        }
        return frontmatter
    }

    public static func filename(for task: TaskItem) -> String {
        let safe = task.title
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let prefix = String(safe.prefix(48)).isEmpty ? "task" : String(safe.prefix(48))
        return "\(prefix)-\(task.id.uuidString.prefix(8)).md"
    }

    public static func parse(_ markdown: String) -> ParsedFrontmatter? {
        guard markdown.hasPrefix("---") else { return nil }
        let lines = markdown.components(separatedBy: .newlines)
        guard lines.first == "---" else { return nil }
        var inFrontmatter = true
        var pairs: [String: String] = [:]
        var body = ""
        for line in lines.dropFirst() {
            if inFrontmatter && line == "---" { inFrontmatter = false; continue }
            if inFrontmatter {
                if let colon = line.firstIndex(of: ":") {
                    let key = line[..<colon].trimmingCharacters(in: .whitespaces)
                    let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                    pairs[key] = value
                }
            } else {
                body += line + "\n"
            }
        }
        return ParsedFrontmatter(pairs: pairs, body: body)
    }

    private static func yamlEscape(_ s: String) -> String {
        if s.contains(":") || s.contains("#") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\\\"") + "\""
        }
        return s
    }

    public struct ParsedFrontmatter {
        public let pairs: [String: String]
        public let body: String

        public func date(_ key: String) -> Date? {
            guard let raw = pairs[key] else { return nil }
            return dateFormatter.date(from: raw)
        }

        public func string(_ key: String) -> String? { pairs[key] }
        public func stringList(_ key: String) -> [String] {
            guard let raw = pairs[key] else { return [] }
            let stripped = raw.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            return stripped.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
    }
}
