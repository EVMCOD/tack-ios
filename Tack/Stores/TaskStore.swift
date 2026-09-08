import SwiftUI
import SwiftData
import Combine

/// Single source of truth for the app's SwiftData store.
/// Lives on the App Group container so the widget extension can read it.
@MainActor
public final class TaskStore: ObservableObject {
    public static let shared = TaskStore()

    public let container: ModelContainer

    /// In-memory snapshot of tasks, refreshed whenever any SwiftData change fires.
    /// Widgets read their own snapshot — see `WidgetTaskLoader`.
    @Published public private(set) var tasks: [TaskItem] = []

    private var cancellables: Set<AnyCancellable> = []

    private init() {
        let schema = Schema([TaskItem.self, TaskList.self, Tag.self])
        let url = Self.storeURL()
        let config = ModelConfiguration(
            schema: schema,
            url: url,
            cloudKitDatabase: .none   // v1: App Group store only. v1.1: add CloudKit private db.
        )
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Last-resort: fall back to in-memory so we never crash on cold launch.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [fallback])
            TKLog.fail.error("Failed to open persistent store: \(error). Falling back to in-memory.")
        }
        seedIfNeeded()
        observe()
    }

    private func observe() {
        NotificationCenter.default
            .publisher(for: ModelContext.didSave)
            .debounce(for: .milliseconds(80), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
        refresh()
    }

    public func refresh() {
        let ctx = container.mainContext
        let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.order), SortDescriptor(\.createdAt, order: .forward)])
        tasks = (try? ctx.fetch(descriptor)) ?? []
    }

    // MARK: - Mutations

    @discardableResult
    public func addTask(title: String, notes: String = "", dueAt: Date? = nil, list: TaskList? = nil, tagNames: [String] = []) -> TaskItem {
        let ctx = container.mainContext
        let inbox = ensureInbox(in: ctx)
        let target = list ?? inbox
        let item = TaskItem(title: title, notes: notes, list: target, dueAt: dueAt)
        item.order = nextOrder(in: ctx)
        // Resolve tags by name (create if missing)
        var tags: [Tag] = []
        for name in tagNames where !name.isEmpty {
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { $0.name == name })
            if let existing = try? ctx.fetch(descriptor).first {
                tags.append(existing)
            } else {
                let new = Tag(name: name)
                ctx.insert(new)
                tags.append(new)
            }
        }
        item.tags = tags
        ctx.insert(item)
        try? ctx.save()
        refresh()
        return item
    }

    public func toggleComplete(_ item: TaskItem) {
        let now = Date()
        if item.status == .done {
            item.status = .open
            item.completedAt = nil
        } else {
            item.status = .done
            item.completedAt = now
        }
        try? container.mainContext.save()
        refresh()
    }

    public func delete(_ item: TaskItem) {
        container.mainContext.delete(item)
        try? container.mainContext.save()
        refresh()
    }

    public func update(_ item: TaskItem, title: String? = nil, notes: String? = nil, dueAt: Date?? = nil, status: TaskStatus? = nil) {
        if let title { item.title = title }
        if let notes { item.notes = notes }
        if let dueAt { item.dueAt = dueAt }
        if let status { item.status = status; item.completedAt = status == .done ? .now : nil }
        try? container.mainContext.save()
        refresh()
    }

    public var inbox: TaskList? {
        let ctx = container.mainContext
        let descriptor = FetchDescriptor<TaskList>(predicate: #Predicate { $0.name == "Inbox" })
        return try? ctx.fetch(descriptor).first
    }

    // MARK: - Helpers

    private func ensureInbox(in ctx: ModelContext) -> TaskList {
        if let existing = try? ctx.fetch(FetchDescriptor<TaskList>(predicate: #Predicate { $0.name == "Inbox" })).first {
            return existing
        }
        let inbox = TaskList(name: "Inbox", icon: "tray", accent: nil, order: 0)
        ctx.insert(inbox)
        return inbox
    }

    private func nextOrder(in ctx: ModelContext) -> Int {
        let descriptor = FetchDescriptor<TaskItem>(sortBy: [SortDescriptor(\.order, order: .reverse)])
        return ((try? ctx.fetch(descriptor).first?.order) ?? 0) + 1
    }

    private func seedIfNeeded() {
        let ctx = container.mainContext
        let count = (try? ctx.fetchCount(FetchDescriptor<TaskList>())) ?? 0
        if count == 0 {
            ctx.insert(TaskList(name: "Inbox",  icon: "tray",  accent: nil, order: 0))
            ctx.insert(TaskList(name: "Today",  icon: "sun.max", accent: nil, order: 1))
            ctx.insert(TaskList(name: "Personal", icon: "leaf", accent: "#4ADE80", order: 2))
            ctx.insert(TaskList(name: "Work",    icon: "briefcase", accent: "#5B8FF9", order: 3))
            try? ctx.save()
        }
    }

    // MARK: - Store URL (App Group)

    private static func storeURL() -> URL {
        let groupID = "group.app.tack.shared"
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            return url.appending(path: "Tack.store")
        }
        // Fallback to Application Support (should be unreachable on a real install).
        let fm = FileManager.default
        let dir = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? fm.temporaryDirectory
        return dir.appending(path: "Tack.store")
    }
}
