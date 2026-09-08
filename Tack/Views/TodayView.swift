import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: TaskStore
    @State private var presentingQuickAdd = false

    // MARK: - Computed

    private var today: [TaskItem] {
        let cal = Calendar.current
        return store.tasks
            .filter { !$0.isCompleted }
            .filter { task in
                guard let d = task.dueAt else { return false }
                return cal.isDateInToday(d)
            }
            .sorted { ($0.dueAt ?? .distantFuture) < ($1.dueAt ?? .distantFuture) }
    }

    private var open: [TaskItem]     { store.tasks.filter { !$0.isCompleted } }
    private var done: [TaskItem]     { store.tasks.filter { $0.isCompleted } }
    private var overdue: [TaskItem] {
        store.tasks.filter { t in
            guard let d = t.dueAt, !t.isCompleted else { return false }
            return d < .now
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: TK.Spacing.lg) {
                hero
                statsStrip
                if today.isEmpty && overdue.isEmpty {
                    emptyState
                } else {
                    section("Today") {
                        ForEach(Array(today.enumerated()), id: \.element.id) { idx, task in
                            TaskRowView(task: task) {
                                withAnimation(TK.Spring.snappy) {
                                    store.toggleComplete(task)
                                }
                            }
                            .tkCard()
                            .tkAppear(index: idx)
                        }
                    }
                    if !overdue.isEmpty {
                        section("Overdue") {
                            ForEach(Array(overdue.enumerated()), id: \.element.id) { idx, task in
                                TaskRowView(task: task) {
                                    withAnimation(TK.Spring.snappy) {
                                        store.toggleComplete(task)
                                    }
                                }
                                .tkCard()
                                .tkAppear(index: idx)
                            }
                        }
                    }
                }
                Spacer(minLength: 80)  // breathing room above the floating + button
            }
            .padding(TK.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(TK.Palette.bgDeep.ignoresSafeArea())
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(alignment: .leading, spacing: TK.Spacing.xs) {
            Text(greeting)
                .font(TK.Typography.sectionHead)
                .foregroundStyle(TK.Palette.textMuted)
                .textCase(.uppercase)
                .tracking(0.6)
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(TK.Palette.textStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("Here's what matters today.")
                .font(.callout)
                .foregroundStyle(TK.Palette.textMuted)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, TK.Spacing.md)
    }

    // MARK: - Stats strip (visible even when today is empty)

    private var statsStrip: some View {
        HStack(spacing: TK.Spacing.sm) {
            metricPill(title: "Open",     value: open.count,    tint: TK.Palette.accent,    system: "circle")
            metricPill(title: "Today",    value: today.count,   tint: TK.Palette.warning,   system: "sun.max.fill")
            metricPill(title: "Done",     value: done.count,    tint: TK.Palette.success,   system: "checkmark.seal.fill")
        }
    }

    private func metricPill(title: String, value: Int, tint: Color, system: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: system)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TK.Palette.textMuted)
                    .textCase(.uppercase)
                    .tracking(0.4)
            }
            Text("\(value)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(TK.Palette.textStrong)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(TK.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: TK.Radius.md, style: .continuous)
                .fill(TK.Palette.surfaceHigh)
                .overlay(
                    RoundedRectangle(cornerRadius: TK.Radius.md, style: .continuous)
                        .stroke(tint.opacity(0.25), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: TK.Spacing.md) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [TK.Palette.warning.opacity(0.45), TK.Palette.warning.opacity(0.0)],
                            center: .center, startRadius: 6, endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)
                ZStack {
                    Circle()
                        .fill(TK.Palette.surfaceHigh)
                        .frame(width: 96, height: 96)
                    Image(systemName: "sun.haze.fill")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(TK.Palette.warning)
                }
            }
            Text("Clear skies")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(TK.Palette.textStrong)
            Text("Nothing due today. Capture something new from the button below, or just enjoy the quiet.")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(TK.Palette.textMuted)
                .frame(maxWidth: 320)
            Button {
                presentingQuickAdd = true
            } label: {
                Label("Add a task", systemImage: "plus.circle.fill")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, TK.Spacing.lg)
                    .padding(.vertical, TK.Spacing.sm + 2)
                    .background(Capsule().fill(TK.Palette.accent))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.tkPress)
            .padding(.top, TK.Spacing.xs)
        }
        .padding(.vertical, TK.Spacing.xxl)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $presentingQuickAdd) {
            QuickAddSheet()
                .environmentObject(store)
        }
    }

    private func section<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: TK.Spacing.sm) {
            Text(title)
                .font(TK.Typography.sectionHead)
                .foregroundStyle(TK.Palette.textMuted)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.horizontal, TK.Spacing.xs)
            content()
        }
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
