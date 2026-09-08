import SwiftUI
import Charts

/// Productivity dashboard. Streak, completion count, distribution by list, last 14 days.
struct StatsView: View {
    @EnvironmentObject private var store: TaskStore

    private var allTasks: [TaskItem] { store.tasks }
    private var completed: [TaskItem] { allTasks.filter { $0.isCompleted } }
    private var open: [TaskItem]     { allTasks.filter { !$0.isCompleted } }
    private var today: [TaskItem]    {
        let cal = Calendar.current
        return open.filter { t in
            if let d = t.dueAt { return cal.isDateInToday(d) }
            return false
        }
    }

    private var streak: Int {
        let cal = Calendar.current
        var count = 0
        var day = cal.startOfDay(for: .now)
        while true {
            let dayEnd = cal.date(byAdding: .day, value: 1, to: day)!
            let onDay = completed.filter { t in
                guard let c = t.completedAt else { return false }
                return c >= day && c < dayEnd
            }.count
            if onDay == 0 && count > 0 { break }
            if onDay > 0 { count += 1 }
            day = cal.date(byAdding: .day, value: -1, to: day)!
            if count > 365 { break }  // sanity bound
        }
        return count
    }

    private var last14: [DayBucket] {
        let cal = Calendar.current
        var buckets: [Date: Int] = [:]
        for offset in 0..<14 {
            let d = cal.date(byAdding: .day, value: -offset, to: .now)!
            buckets[cal.startOfDay(for: d)] = 0
        }
        for t in completed {
            guard let c = t.completedAt else { continue }
            let key = cal.startOfDay(for: c)
            if buckets[key] != nil { buckets[key]! += 1 }
        }
        return buckets
            .map { DayBucket(date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }

    private var byList: [ListStat] {
        var dict: [String: Int] = [:]
        for t in completed { dict[t.listName, default: 0] += 1 }
        return dict
            .map { ListStat(name: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: TK.Spacing.lg) {
                streakCard
                metricsRow
                chartCard
                byListCard
            }
            .padding(TK.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Stats")
        .background(TK.Palette.bgDeep.ignoresSafeArea())
    }

    // MARK: - Sections

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: TK.Spacing.sm) {
            HStack {
                Image(systemName: TK.Icon.streak)
                    .font(.title2)
                    .foregroundStyle(TK.Palette.streak)
                Text("Streak")
                    .font(TK.Typography.sectionHead)
                    .foregroundStyle(TK.Palette.textMuted)
                    .textCase(.uppercase)
                Spacer()
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(streak)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(TK.Gradient.streak)
                    .monospacedDigit()
                Text(streak == 1 ? "day" : "days")
                    .font(.title3)
                    .foregroundStyle(TK.Palette.textMuted)
            }
            Text(streak == 0
                 ? "Complete a task today to start a streak."
                 : "Keep shipping. Don't break the chain.")
                .font(.callout)
                .foregroundStyle(TK.Palette.textMuted)
        }
        .padding(TK.Spacing.lg)
        .tkHero(accent: TK.Palette.streak)
    }

    private var metricsRow: some View {
        HStack(spacing: TK.Spacing.sm) {
            metric("Open",     value: open.count, system: "circle", tint: TK.Palette.accent)
            metric("Today",    value: today.count, system: "sun.max", tint: TK.Palette.warning)
            metric("Completed", value: completed.count, system: "checkmark.seal.fill", tint: TK.Palette.success)
        }
    }

    private func metric(_ label: String, value: Int, system: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: system)
                .foregroundStyle(tint)
                .font(.callout)
            Text("\(value)")
                .font(TK.Typography.metric)
                .foregroundStyle(TK.Palette.textStrong)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(TK.Typography.caption)
                .foregroundStyle(TK.Palette.textMuted)
        }
        .padding(TK.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tkCard()
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: TK.Spacing.sm) {
            Text("Last 14 days")
                .font(TK.Typography.sectionHead)
                .foregroundStyle(TK.Palette.textMuted)
                .textCase(.uppercase)
            Chart(last14) { bucket in
                BarMark(
                    x: .value("Day", bucket.date, unit: .day),
                    y: .value("Done", bucket.count)
                )
                .cornerRadius(4)
                .foregroundStyle(
                    bucket.count > 0
                        ? AnyShapeStyle(TK.Palette.success.gradient)
                        : AnyShapeStyle(TK.Palette.surfaceHigh)
                )
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day(.defaultDigits))
                        .foregroundStyle(TK.Palette.textTertiary)
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 140)
        }
        .padding(TK.Spacing.md)
        .tkCard()
    }

    private var byListCard: some View {
        VStack(alignment: .leading, spacing: TK.Spacing.sm) {
            Text("By list")
                .font(TK.Typography.sectionHead)
                .foregroundStyle(TK.Palette.textMuted)
                .textCase(.uppercase)
            if byList.isEmpty {
                Text("No data yet.")
                    .font(.callout)
                    .foregroundStyle(TK.Palette.textMuted)
                    .padding(.vertical, TK.Spacing.md)
            } else {
                ForEach(byList) { stat in
                    HStack {
                        Text(stat.name)
                            .font(.callout.weight(.medium))
                        Spacer()
                        Text("\(stat.count)")
                            .font(.callout.monospacedDigit().weight(.semibold))
                            .foregroundStyle(TK.Palette.textMuted)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(TK.Spacing.md)
        .tkCard()
    }
}

private struct DayBucket: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}

private struct ListStat: Identifiable {
    let name: String
    let count: Int
    var id: String { name }
}

#Preview {
    NavigationStack { StatsView() }
        .environmentObject(TaskStore.shared)
        .preferredColorScheme(.dark)
        .background(TK.Palette.bgDeep)
}
