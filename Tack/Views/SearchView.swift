import SwiftUI

/// Global search across tasks.
struct SearchView: View {
    @EnvironmentObject private var store: TaskStore
    @State private var query: String = ""
    @FocusState private var searchFocused: Bool

    private var results: [TaskItem] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return store.tasks.filter { task in
            task.title.localizedCaseInsensitiveContains(q)
                || task.notes.localizedCaseInsensitiveContains(q)
                || task.listName.localizedCaseInsensitiveContains(q)
                || task.tags.contains(where: { $0.name.localizedCaseInsensitiveContains(q) })
        }
        .sorted { $0.createdAt > $1.createdAt }
        .prefix(50)
        .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(.horizontal)
                .padding(.top, TK.Spacing.sm)

            if query.isEmpty {
                EmptyStateView(
                    system: TK.Icon.search,
                    title: "Search everything",
                    subtitle: "Find a task by title, notes, list, or #tag."
                )
                Spacer()
            } else if results.isEmpty {
                EmptyStateView(
                    system: "magnifyingglass",
                    title: "No matches",
                    subtitle: "Try a different word, or check the spelling."
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: TK.Spacing.xs) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { idx, t in
                            TaskRowView(task: t) {
                                withAnimation(TK.Spring.snappy) { store.toggleComplete(t) }
                            }
                            .tkCard()
                            .tkAppear(index: idx)
                        }
                    }
                    .padding(TK.Spacing.lg)
                }
            }
        }
        .navigationTitle("Search")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(TK.Palette.bgDeep.ignoresSafeArea())
        .onAppear { searchFocused = true }
    }

    private var searchField: some View {
        HStack(spacing: TK.Spacing.xs) {
            Image(systemName: TK.Icon.search)
                .foregroundStyle(TK.Palette.textMuted)
            TextField("Search tasks", text: $query)
                .focused($searchFocused)
                .submitLabel(.search)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TK.Palette.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(TK.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: TK.Radius.md)
                .fill(TK.Palette.surfaceHigh)
        )
    }
}
