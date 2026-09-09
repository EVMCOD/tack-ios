import SwiftUI
import SwiftData

struct TaskDetailView: View {
    let taskID: UUID
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var hasDue: Bool = false
    @State private var dueDate: Date = .now
    @State private var status: TaskStatus = .open
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title, axis: .vertical)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1...4)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...12)
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases) { s in
                            Label(s.label, systemImage: s.sfSymbol).tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("Due") {
                    Toggle("Has due date", isOn: $hasDue.animation())
                    if hasDue {
                        DatePicker("Due", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                Section {
                    Button(role: .destructive) {
                        if let task = store.tasks.first(where: { $0.id == taskID }) {
                            store.delete(task)
                        }
                        dismiss()
                    } label: {
                        Label("Delete task", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded, let task = store.tasks.first(where: { $0.id == taskID }) else { return }
        title = task.title
        notes = task.notes
        hasDue = task.dueAt != nil
        dueDate = task.dueAt ?? .now
        status = task.status
        loaded = true
    }

    private func save() {
        guard let task = store.tasks.first(where: { $0.id == taskID }) else { return }
        store.update(
            task,
            title: title.isEmpty ? nil : title,
            notes: notes,
            dueAt: hasDue ? .some(dueDate) : .some(nil),
            status: status
        )
    }
}
