import SwiftUI

/// Single task row, shared between list views and widgets.
struct TaskRowView: View {
    let task: TaskItem
    let onToggle: () -> Void
    let compact: Bool

    init(task: TaskItem, onToggle: @escaping () -> Void, compact: Bool = false) {
        self.task = task
        self.onToggle = onToggle
        self.compact = compact
    }

    var body: some View {
        HStack(alignment: .top, spacing: TK.Spacing.sm) {
            Button(action: onToggle) {
                Image(systemName: statusIcon)
                    .font(.system(size: compact ? 18 : 22, weight: .regular))
                    .foregroundStyle(statusColor)
                    .padding(.top, 2)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .tkHoverable()

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.system(size: compact ? 14 : 16, weight: .medium, design: .default))
                    .strikethrough(task.status == .done)
                    .foregroundStyle(task.status == .done ? TK.Palette.textTertiary : TK.Palette.textStrong)
                    .lineLimit(compact ? 1 : 2)

                if !compact {
                    HStack(spacing: TK.Spacing.xs) {
                        if !task.listName.isEmpty {
                            Pill(text: task.listName, system: listIcon, tint: TK.Palette.accentMuted)
                        }
                        if let due = task.dueAt {
                            Pill(text: dueLabel(due), system: "calendar", tint: dueColor(due))
                        }
                        ForEach(task.tags.prefix(2)) { tag in
                            Pill(text: tag.name, system: "tag", tint: Color.gray.opacity(0.18))
                        }
                        if task.tags.count > 2 {
                            Text("+\(task.tags.count - 2)")
                                .font(.caption2).foregroundStyle(TK.Palette.textTertiary)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            if !task.notes.isEmpty && !compact {
                Image(systemName: "text.alignleft")
                    .font(.caption)
                    .foregroundStyle(TK.Palette.textTertiary)
            }
        }
        .padding(.vertical, compact ? 6 : 10)
        .padding(.horizontal, TK.Spacing.sm)
        .contentShape(Rectangle())
    }

    private var statusIcon: String {
        switch task.status {
        case .open:        return "circle"
        case .inProgress:  return "circle.lefthalf.filled"
        case .done:        return "checkmark.circle.fill"
        case .cancelled:   return "xmark.circle"
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .open:        return TK.Palette.statusOpen
        case .inProgress:  return TK.Palette.statusInProgress
        case .done:        return TK.Palette.statusDone
        case .cancelled:   return TK.Palette.statusCancelled
        }
    }

    private var listIcon: String {
        switch task.listName {
        case "Inbox":    return "tray"
        case "Today":    return "sun.max"
        case "Personal": return "leaf"
        case "Work":     return "briefcase"
        default:         return "list.bullet"
        }
    }

    private func dueLabel(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInTomorrow(d) { return "Tomorrow" }
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: d)
    }

    private func dueColor(_ d: Date) -> Color {
        if d < .now { return TK.Palette.danger.opacity(0.18) }
        if Calendar.current.isDateInToday(d) { return TK.Palette.warning.opacity(0.22) }
        return TK.Palette.accentMuted
    }
}

private struct Pill: View {
    let text: String
    let system: String
    let tint: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: system).font(.caption2)
            Text(text).font(.caption2.weight(.medium))
        }
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(
            Capsule().fill(tint)
        )
        .foregroundStyle(TK.Palette.textStrong)
    }
}
