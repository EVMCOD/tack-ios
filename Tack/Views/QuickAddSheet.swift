import SwiftUI

struct QuickAddSheet: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var integrations: IntegrationHub
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var hasDue: Bool = false
    @State private var due: Date = .now.addingTimeInterval(3600)
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: TK.Spacing.md) {
                TextField("What's next?", text: $title, axis: .vertical)
                    .font(.title2.weight(.semibold))
                    .focused($titleFocused)
                    .lineLimit(1...4)
                    .padding(TK.Spacing.md)
                    .background(TK.Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: TK.Radius.md))
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...8)
                    .padding(TK.Spacing.md)
                    .background(TK.Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: TK.Radius.md))
                Toggle("Set a due date", isOn: $hasDue.animation())
                if hasDue {
                    DatePicker("Due", selection: $due, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal, TK.Spacing.sm)
                }
                Spacer()
            }
            .padding(TK.Spacing.lg)
            .navigationTitle("New task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let new = store.addTask(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            notes: notes,
                            dueAt: hasDue ? due : nil
                        )
                        Task { await integrations.propagateToIntegrations(new) }
                        dismiss()
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { titleFocused = true }
            .background(TK.Palette.bgDeep.ignoresSafeArea())
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }
}
