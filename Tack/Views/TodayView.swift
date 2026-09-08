import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: TaskStore

    private var tasksToday: [TaskItem] {
        let cal = Calendar.current
        return store.tasks
            .filter { !$0.isCompleted }
            .filter { task in
                guard let d = task.dueAt else { return false }
                return cal.isDateInToday(d)
            }
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TK.Spacing.lg) {
                header
                if tasksToday.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(tasksToday.enumerated()), id: \.element.id) { idx, task in
                        TaskRowView(task: task) {
                            withAnimation(TK.Spring.snappy) { store.toggleComplete(task) }
                        }
                        .tkAppear(index: idx)
                        .tkCard()
                    }
                }
            }
            .padding(TK.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Today")
        .background(TK.Palette.bgDeep.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(TK.Palette.textMuted)
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(TK.Palette.textStrong)
        }
        .padding(.bottom, TK.Spacing.sm)
    }

    private var emptyState: some View {
        VStack(spacing: TK.Spacing.md) {
            Image(systemName: "sun.haze")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(TK.Palette.warning.opacity(0.7))
            Text("Clear skies")
                .font(.title2.weight(.semibold))
                .foregroundStyle(TK.Palette.textStrong)
            Text("Nothing due today. Capture something new from the + button.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(TK.Palette.textMuted)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, TK.Spacing.xxl)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 4..<12:  return "Good morning"
        case 12..<18: return "Good afternoon"
        case 18..<22: return "Good evening"
        default:      return "Late night"
        }
    }
}

#Preview {
    NavigationStack { TodayView() }
        .environmentObject(TaskStore.shared)
        .preferredColorScheme(.dark)
        .background(TK.Palette.bgDeep)
}
