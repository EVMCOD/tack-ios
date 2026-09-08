import SwiftUI

struct QuickAddSheet: View {
    @EnvironmentObject private var store: TaskStore
    @EnvironmentObject private var integrations: IntegrationHub
    @Environment(\.dismiss) private var dismiss
    @State private var rawText: String = ""
    @State private var hasDue: Bool = false
    @State private var due: Date = .now.addingTimeInterval(3600)
    @State private var parsedTags: [String] = []
    @State private var parsedPriority: NaturalLanguageParser.Priority?
    @State private var parsedDue: Date?
    @State private var parsing: Bool = false
    @FocusState private var titleFocused: Bool

    private var parsedTitle: String {
        NaturalLanguageParser.parse(rawText).cleanTitle
    }

    private var detectionSummary: String {
        var bits: [String] = []
        if let parsedDue {
            let f = DateFormatter()
            f.dateStyle = .medium; f.timeStyle = .short
            bits.append("📅 \(f.string(from: parsedDue))")
        }
        if !parsedTags.isEmpty {
            bits.append("🏷️ \(parsedTags.map { "#" + $0 }.joined(separator: " "))")
        }
        if let p = parsedPriority {
            bits.append("⚡︎ \(p.raw.dropFirst())")
        }
        return bits.joined(separator: "  •  ")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: TK.Spacing.md) {
                TextField("Buy milk tomorrow 5pm #groceries", text: $rawText, axis: .vertical)
                    .font(.title3.weight(.semibold))
                    .focused($titleFocused)
                    .lineLimit(1...6)
                    .padding(TK.Spacing.md)
                    .background(TK.Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: TK.Radius.md))
                    .onChange(of: rawText) { _, _ in
                        let parsed = NaturalLanguageParser.parse(rawText)
                        withAnimation(TK.Spring.snappy) {
                            parsedTags    = parsed.tags
                            parsedPriority = parsed.priority
                            parsedDue     = parsed.dueAt
                            hasDue        = parsed.dueAt != nil
                            if let d = parsed.dueAt { due = d }
                        }
                    }

                if !detectionSummary.isEmpty {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(TK.Palette.accent)
                        Text(detectionSummary)
                            .font(.caption)
                            .foregroundStyle(TK.Palette.textMuted)
                        Spacer()
                    }
                    .padding(.horizontal, TK.Spacing.sm)
                }

                Toggle("Set a due date", isOn: $hasDue.animation())
                if hasDue {
                    DatePicker("Due", selection: $due, displayedComponents: [.date, .hourAndMinute])
                        .padding(.horizontal, TK.Spacing.sm)
                }

                if rawText.isEmpty {
                    Text("Tip: type things like \"review PR in 3 days #work\" or \"call John next monday 10am\".")
                        .font(.caption)
                        .foregroundStyle(TK.Palette.textTertiary)
                        .padding(.top, TK.Spacing.xs)
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
                            title: parsedTitle,
                            notes: "",
                            dueAt: hasDue ? due : nil
                        )
                        Task { await integrations.propagateToIntegrations(new) }
                        dismiss()
                    }
                    .bold()
                    .disabled(parsedTitle.isEmpty)
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

#Preview {
    QuickAddSheet()
        .environmentObject(TaskStore.shared)
        .environmentObject(IntegrationHub.shared)
        .preferredColorScheme(.dark)
}
