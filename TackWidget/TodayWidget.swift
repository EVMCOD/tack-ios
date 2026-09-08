import WidgetKit
import SwiftUI
import AppIntents

struct TodayWidget: Widget {
    let kind: String = TaskWidgetKind.today.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskTimelineProvider(todayOnly: true, displayName: "Today")) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Your tasks for today.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodayWidgetView: View {
    let entry: TaskEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:  smallLayout
        case .systemMedium: mediumLayout
        case .systemLarge:  largeLayout
        default:            mediumLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sun.max.fill").foregroundStyle(.orange)
                Text("Today").font(.headline)
            }
            Spacer()
            Text("\(entry.tasks.count)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)
            Text(entry.tasks.isEmpty ? "All done" : "tasks due")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sun.max.fill").foregroundStyle(.orange)
                Text("Today").font(.headline)
                Spacer()
                Text(Date.now, format: .dateTime.weekday(.abbreviated).day())
                    .font(.caption).foregroundStyle(.secondary)
            }
            if entry.tasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.green)
                        Text("Clear skies").font(.callout)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.tasks.prefix(3)) { t in
                    HStack(spacing: 8) {
                        Image(systemName: "circle").foregroundStyle(.orange)
                        Text(t.title).lineLimit(1)
                    }
                    .font(.callout)
                }
                if entry.tasks.count > 3 {
                    Text("+ \(entry.tasks.count - 3) more")
                        .font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            mediumLayout
            if entry.tasks.count > 3 {
                Divider()
                ForEach(entry.tasks.dropFirst(3).prefix(5)) { t in
                    HStack(spacing: 8) {
                        Image(systemName: "circle").foregroundStyle(.orange)
                        Text(t.title).lineLimit(1)
                    }
                    .font(.callout)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
