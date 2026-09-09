import SwiftUI
import SwiftData
import AppIntents

@main
struct TackApp: App {
    @StateObject private var store = TaskStore.shared
    @StateObject private var integrations = IntegrationHub.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingQuickAdd = false

    init() {
        // Register AppIntents shortcut phrases as soon as possible.
        TackAppShortcuts.updateAppShortcutParameters()
        // Seed demo data on first launch so the UI looks inhabited, not empty.
        TaskStore.shared.seedDemoDataOnFirstLaunch()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(integrations)
                .preferredColorScheme(nil)   // Honor system; user can override in Settings.
                #if os(macOS)
                .frame(minWidth: 880, minHeight: 600)
                #endif
        }
        .modelContainer(store.container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                integrations.scheduleBackgroundRefresh()
            case .active:
                integrations.refreshOnLaunch()
            default:
                break
            }
        }

        #if os(macOS)
        // Menu-bar extra — Quick Add without leaving the current app.
        // Hidden when onboarding isn't done so we don't show the bar item
        // to brand-new users who haven't entered the app yet.
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(store)
        } label: {
            Image(systemName: "checklist")
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}

#if os(macOS)
/// Popover content for the menu-bar item.
private struct MenuBarContent: View {
    @EnvironmentObject private var store: TaskStore
    @State private var title: String = ""
    @FocusState private var focused: Bool

    private var openTasks: [TaskItem] {
        store.tasks.filter { !$0.isCompleted }.prefix(8).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Add").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            HStack {
                TextField("What's next?", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .onSubmit(add)
                Button("Add", action: add)
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Divider()
            Text("Open tasks").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            if openTasks.isEmpty {
                Text("Nothing open.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(openTasks) { task in
                    Button {
                        store.toggleComplete(task)
                    } label: {
                        HStack {
                            Image(systemName: task.status == .done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(task.status == .done ? .green : .secondary)
                            Text(task.title).lineLimit(1)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Divider()
            Button("Open Tack…") {
                NSApp.activate(ignoringOtherApps: true)
                if let url = URL(string: "tack://open") { NSWorkspace.shared.open(url) }
            }
            .buttonStyle(.borderless)
        }
        .padding(TK.Spacing.md)
        .frame(width: 360)
        .onAppear { focused = true }
    }

    private func add() {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let parsed = NaturalLanguageParser.parse(trimmed)
        let task = store.addTask(
            title: parsed.cleanTitle,
            notes: "",
            dueAt: parsed.dueAt,
            tagNames: parsed.tags
        )
        Task { await IntegrationHub.shared.propagateToIntegrations(task) }
        title = ""
    }
}
#endif
