import SwiftUI
import SwiftData

/// Adaptive shell: TabView on iOS, NavigationSplitView on macOS.
struct RootView: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var integrations: IntegrationHub
    @State private var selection: Tab = .today
    @State private var presentingQuickAdd = false

    enum Tab: Hashable {
        case today, inbox, lists, settings
    }

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            detail
        }
        .sheet(isPresented: $presentingQuickAdd) {
            QuickAddSheet()
                .environmentObject(store)
                .environmentObject(integrations)
        }
        #else
        TabView(selection: $selection) {
            NavigationStack { TodayView() }
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(Tab.today)
            NavigationStack { InboxView() }
                .tabItem { Label("Inbox", systemImage: "tray") }
                .tag(Tab.inbox)
            NavigationStack { ListsView() }
                .tabItem { Label("Lists", systemImage: "list.bullet.rectangle") }
                .tag(Tab.lists)
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .sheet(isPresented: $presentingQuickAdd) {
            QuickAddSheet()
                .environmentObject(store)
                .environmentObject(integrations)
        }
        .overlay(alignment: .bottomTrailing) {
            QuickAddButton { presentingQuickAdd = true }
                .padding(.trailing, TK.Spacing.lg)
                .padding(.bottom, TK.Spacing.xxl)
        }
        #endif
    }

    #if os(macOS)
    private var sidebar: some View {
        List(selection: $selection) {
            Label("Today",   systemImage: "sun.max").tag(Tab.today)
            Label("Inbox",   systemImage: "tray").tag(Tab.inbox)
            Label("Lists",   systemImage: "list.bullet.rectangle").tag(Tab.lists)
            Divider()
            Label("Settings", systemImage: "gearshape").tag(Tab.settings)
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button {
                presentingQuickAdd = true
            } label: {
                Label("Quick Add", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .today:    TodayView()
        case .inbox:    InboxView()
        case .lists:    ListsView()
        case .settings: SettingsView()
        }
    }
    #endif
}

private struct QuickAddButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(TK.Palette.accent)
                        .shadow(color: TK.Palette.accentGlow, radius: 12, x: 0, y: 6)
                )
        }
        .accessibilityLabel("Quick Add")
        .tkHoverable()
    }
}
