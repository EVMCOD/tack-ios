import Foundation
import SwiftData

/// A single task. Synced by App Group container; widget reads the same store.
@Model
public final class TaskItem {
    /// Stable UUID — survives rename, used as Notion page id reference and Obsidian filename base.
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var notes: String
    public var createdAt: Date
    public var dueAt: Date?
    public var completedAt: Date?
    public var order: Int

    /// Status enum stored as String for forward compatibility across schema migrations.
    public var statusRaw: String

    /// Source-of-truth dictating which integration owns this row (if any).
    public var origin: String   // "local" | "notion" | "obsidian"

    /// The remote id once linked to an external system. For Notion: page UUID.
    /// For Obsidian: relative path within vault.
    public var remoteID: String?

    /// Last successful sync timestamp for either Notion or Obsidian.
    public var lastSyncedAt: Date?

    /// Denormalized for fast widget reads.
    public var listRemoteID: String?
    public var listName: String

    @Relationship(inverse: \TaskList.tasks)
    public var list: TaskList?

    @Relationship(inverse: \Tag.tasks)
    public var tags: [Tag] = []

    public var status: TaskStatus {
        get { TaskStatus(rawValue: statusRaw) ?? .open }
        set { statusRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        list: TaskList? = nil,
        dueAt: Date? = nil,
        status: TaskStatus = .open,
        origin: String = Origin.local
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.createdAt = .now
        self.dueAt = dueAt
        self.completedAt = nil
        self.order = 0
        self.statusRaw = status.rawValue
        self.origin = origin
        self.remoteID = nil
        self.lastSyncedAt = nil
        self.listRemoteID = list?.remoteID
        self.listName = list?.name ?? "Inbox"
        self.list = list
    }
}

extension TaskItem {
    public enum Origin {
        public static let local = "local"
        public static let notion = "notion"
        public static let obsidian = "obsidian"
    }

    public var isCompleted: Bool {
        status == .done || status == .cancelled
    }
}

public enum TaskStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case open
    case inProgress = "in_progress"
    case done
    case cancelled

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .open:       return "Open"
        case .inProgress: return "In Progress"
        case .done:       return "Done"
        case .cancelled:  return "Cancelled"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .open:       return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .done:       return "checkmark.circle.fill"
        case .cancelled:  return "xmark.circle"
        }
    }
}
