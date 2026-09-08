import Foundation
import SwiftData

/// A collection of tasks. Pre-seeded with Inbox; user can create more.
@Model
public final class TaskList {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var createdAt: Date
    public var order: Int
    public var accentHex: String?     // "#RRGGBB" or nil to inherit
    public var iconSF: String         // SF Symbol name

    /// Remote identifier when the list is mirrored from Notion/Obsidian.
    public var remoteID: String?
    public var origin: String         // "local" | "notion" | "obsidian"
    public var lastSyncedAt: Date?

    @Relationship(deleteRule: .cascade)
    public var tasks: [TaskItem] = []

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "list.bullet",
        accent: String? = nil,
        order: Int = 0,
        origin: String = TaskItem.Origin.local
    ) {
        self.id = id
        self.name = name
        self.createdAt = .now
        self.order = order
        self.accentHex = accent
        self.iconSF = icon
        self.remoteID = nil
        self.origin = origin
        self.lastSyncedAt = nil
    }

    public static let inbox = "Inbox"
    public static let today = "Today"
    public static let upcoming = "Upcoming"
    public static let completed = "Completed"
}
