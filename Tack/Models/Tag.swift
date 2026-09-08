import Foundation
import SwiftData

/// Free-form tag. Many-to-many with `TaskItem`.
@Model
public final class Tag {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var accentHex: String?
    public var createdAt: Date

    public var tasks: [TaskItem] = []

    public init(id: UUID = UUID(), name: String, accentHex: String? = nil) {
        self.id = id
        self.name = name
        self.accentHex = accentHex
        self.createdAt = .now
    }
}
