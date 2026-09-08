import SwiftUI

struct InboxView: View {
    @EnvironmentObject private var store: TaskStore
    @State private var selected: TaskItem?

    private var openTasks: [TaskItem] {
        store.tasks.filter { !$0.isCompleted && ($0.listName == "Inbox") }
                    .sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TK.Spacing.md) {
                header
                ForEach(Array(openTasks.enumerated()), id: \.element.id) { idx, t in
                    Button {
                        selected = t
                    } label: {
                        TaskRowView(task: t) {
                            withAnimation(TK.Spring.snappy) { store.toggleComplete(t) }
                        }
                    }
                    .buttonStyle(.plain)
                    .tkCard()
                    .tkAppear(index: idx)
                }
            }
            .padding(TK.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Inbox")
        .background(TK.Palette.bgDeep.ignoresSafeArea())
        .sheet(item: $selected) { task in
            TaskDetailView(taskID: task.id)
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(openTasks.count) pending")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(TK.Palette.textStrong)
                Text("Captures land here. Move them out when you're ready.")
                    .font(.callout)
                    .foregroundStyle(TK.Palette.textMuted)
            }
            Spacer()
        }
        .padding(.bottom, TK.Spacing.sm)
    }
}
