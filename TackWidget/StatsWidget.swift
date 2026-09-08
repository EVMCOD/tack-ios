import WidgetKit
import SwiftUI
import Charts

struct StatsWidget: Widget {
    let kind: String = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsTimelineProvider()) { entry in
            StatsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Stats")
        .description("Your streak and weekly completion count.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct StatsWidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let last7: [DayBucket]
    let openCount: Int
    let todayCount: Int
}

struct StatsTimelineProvider: TimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> StatsWidgetEntry {
        StatsWidgetEntry(
            date: .now, streak: 7,
            last7: (0..<7).map { DayBucket(date: Date.now.addingTimeInterval(-Double($0) * 86400), count: Int.random(in: 0...5)) },
            openCount: 12, todayCount: 3
        )
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (StatsWidgetEntry) -> Void) {
        completion(loadStats())
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsWidgetEntry>) -> Void) {
        let entry = loadStats()
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    @MainActor
    private func loadStats() -> StatsWidgetEntry {
        let tasks = WidgetTaskLoader.tasks(todayOnly: false)
        let completed = tasks.filter { $0.isCompleted }
        let cal = Calendar.current
        var streak = 0
        var day = cal.startOfDay(for: .now)
        while true {
            let end = cal.date(byAdding: .day, value: 1, to: day)!
            let has = completed.contains { t in
                guard let c = t.completedAt else { return false }
                return c >= day && c < end
            }
            if has { streak += 1 }
            else if streak > 0 { break }
            day = cal.date(byAdding: .day, value: -1, to: day)!
            if streak > 365 { break }
        }
        var buckets: [DayBucket] = []
        for offset in 0..<7 {
            let d = cal.date(byAdding: .day, value: -offset, to: .now)!
            let start = cal.startOfDay(for: d)
            let end = cal.date(byAdding: .day, value: 1, to: start)!
            let count = completed.filter { t in
                guard let c = t.completedAt else { return false }
                return c >= start && c < end
            }.count
            buckets.append(DayBucket(date: start, count: count))
        }
        let today = tasks.filter { t in
            guard let d = t.dueAt else { return false }
            return cal.isDateInToday(d)
        }.count

        return StatsWidgetEntry(
            date: .now, streak: streak,
            last7: buckets.reversed(),
            openCount: tasks.count,
            todayCount: today
        )
    }
}

struct StatsWidgetView: View {
    let entry: StatsWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  smallLayout
        case .systemMedium: mediumLayout
        default:            mediumLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text("Streak").font(.caption.weight(.semibold))
            }
            Text("\(entry.streak)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
                .monospacedDigit()
            Text(entry.streak == 1 ? "day" : "days")
                .font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text("\(entry.todayCount) due today")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumLayout: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                    Text("Streak").font(.caption.weight(.semibold))
                }
                Text("\(entry.streak)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)
                    .monospacedDigit()
                Text(entry.streak == 1 ? "day" : "days")
                    .font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("\(entry.todayCount) due • \(entry.openCount) open")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .frame(width: 110, alignment: .leading)
            Chart(entry.last7) { b in
                BarMark(x: .value("Day", b.date, unit: .day), y: .value("Done", b.count))
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(2)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct DayBucket: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}
