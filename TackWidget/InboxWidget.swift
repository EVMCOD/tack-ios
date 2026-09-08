import WidgetKit
import SwiftUI

struct InboxWidget: Widget {
    let kind: String = TaskWidgetKind.inbox.rawValue

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TaskTimelineProvider(todayOnly: false, displayName: "Inbox")) { entry in
            InboxWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Inbox")
        .description("What's in your Tack inbox.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct InboxWidgetView: View {
    let entry: TaskEntry
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
                Image(systemName: "tray.fill").foregroundStyle(.blue)
                Text("Inbox").font(.headline)
            }
            Spacer()
            Text("\(entry.tasks.count)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundStyle(.blue)
            Text("pending")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tray.fill").foregroundStyle(.blue)
                Text("Inbox").font(.headline)
                Spacer()
                Text("\(entry.tasks.count) pending")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            if entry.tasks.isEmpty {
                Spacer()
                HStack { Spacer(); Text("Empty").foregroundStyle(.secondary); Spacer() }
                Spacer()
            } else {
                ForEach(entry.tasks.prefix(4)) { t in
                    HStack(spacing: 8) {
                        Image(systemName: "circle").foregroundStyle(.blue)
                        Text(t.title).lineLimit(1)
                    }
                    .font(.callout)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
