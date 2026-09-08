import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var ctx
    @EnvironmentObject private var store: TaskStore
    @Query(sort: [SortDescriptor(\TaskList.order), SortDescriptor(\TaskList.name)])
    private var lists: [TaskList]
    @State private var newListName: String = ""
    @State private var creating: Bool = false

    var body: some View {
        List {
            Section("Smart") {
                NavigationLink(value: "today") {
                    Label("Today", systemImage: "sun.max").foregroundStyle(TK.Palette.warning)
                }
                NavigationLink(value: "upcoming") {
                    Label("Upcoming", systemImage: "calendar").foregroundStyle(TK.Palette.accent)
                }
                NavigationLink(value: "completed") {
                    Label("Completed", systemImage: "checkmark.seal").foregroundStyle(TK.Palette.success)
                }
            }
            Section("Your lists") {
                ForEach(lists) { list in
                    NavigationLink(value: list.id) {
                        HStack {
                            Image(systemName: list.iconSF)
                                .foregroundStyle(TK.Palette.accent)
                                .frame(width: 22)
                            Text(list.name)
                            Spacer()
                            Text("\(list.tasks.filter { !$0.isCompleted }.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(TK.Palette.textMuted)
                        }
                    }
                }
                .onDelete(perform: deleteLists)
            }
        }
        .navigationTitle("Lists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    creating = true
                } label: {
                    Label("New list", systemImage: "plus")
                }
            }
        }
        .alert("New list", isPresented: $creating) {
            TextField("Name", text: $newListName)
            Button("Create") {
                addList(name: newListName)
                newListName = ""
            }
            Button("Cancel", role: .cancel) { newListName = "" }
        }
        .navigationDestination(for: UUID.self) { id in
            if let list = lists.first(where: { $0.id == id }) {
                ListDetailView(list: list)
            } else {
                Text("List not found").foregroundStyle(TK.Palette.textMuted)
            }
        }
        .navigationDestination(for: String.self) { key in
            switch key {
            case "today":     SmartListView(kind: .today)
            case "upcoming":  SmartListView(kind: .upcoming)
            case "completed": SmartListView(kind: .completed)
            default:          Text("Unknown").foregroundStyle(TK.Palette.textMuted)
            }
        }
    }

    private func addList(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let next = (lists.last?.order ?? 0) + 1
        let list = TaskList(name: trimmed, icon: "list.bullet", accent: nil, order: next)
        ctx.insert(list)
        try? ctx.save()
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets {
            ctx.delete(lists[index])
        }
        try? ctx.save()
    }
}

enum SmartListKind {
    case today, upcoming, completed
}

struct SmartListView: View {
    let kind: SmartListKind
    @EnvironmentObject private var store: TaskStore

    private var title: String {
        switch kind { case .today: return "Today"; case .upcoming: return "Upcoming"; case .completed: return "Completed" }
    }

    private var tasks: [TaskItem] {
        let cal = Calendar.current
        switch kind {
        case .today:
            return store.tasks.filter { t in
                if let d = t.dueAt { return cal.isDateInToday(d) }
                return false
            }
        case .upcoming:
            return store.tasks
                .filter { !$0.isCompleted }
                .filter { t in
                    guard let d = t.dueAt else { return false }
                    return d > .now && !cal.isDateInToday(d)
                }
                .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
        case .completed:
            return store.tasks.filter { $0.isCompleted }
                                .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TK.Spacing.md) {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { idx, t in
                    TaskRowView(task: t) {
                        withAnimation(TK.Spring.snappy) { store.toggleComplete(t) }
                    }
                    .tkCard()
                    .tkAppear(index: idx)
                }
            }
            .padding(TK.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(title)
        .background(TK.Palette.bgDeep.ignoresSafeArea())
    }
}

struct ListDetailView: View {
    let list: TaskList
    @EnvironmentObject private var store: TaskStore

    var body: some View {
        let items = list.tasks.filter { !$0.isCompleted }
        ScrollView {
            VStack(alignment: .leading, spacing: TK.Spacing.md) {
                HStack {
                    Image(systemName: list.iconSF)
                        .foregroundStyle(TK.Palette.accent)
                    Text(list.name).font(.title2.weight(.semibold))
                }
                if items.isEmpty {
                    Text("Empty.")
                        .foregroundStyle(TK.Palette.textMuted)
                        .padding(.top, TK.Spacing.lg)
                } else {
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, t in
                        TaskRowView(task: t) {
                            withAnimation(TK.Spring.snappy) { store.toggleComplete(t) }
                        }
                        .tkCard()
                        .tkAppear(index: idx)
                    }
                }
            }
            .padding(TK.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(list.name)
        .background(TK.Palette.bgDeep.ignoresSafeArea())
    }
}
