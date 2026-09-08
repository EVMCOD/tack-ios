import SwiftUI

struct ObsidianSettingsView: View {
    @EnvironmentObject private var integrations: IntegrationHub
    @ObservedObject private var vault = ObsidianVault.shared
    @State private var pickerOpen = false

    var body: some View {
        Form {
            Section {
                if let url = vault.url {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current vault")
                            .font(.caption).foregroundStyle(TK.Palette.textMuted)
                        Text(url.lastPathComponent)
                            .font(.body.weight(.semibold))
                        Text(url.deletingLastPathComponent().path)
                            .font(.caption)
                            .foregroundStyle(TK.Palette.textTertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Button("Pick another vault…") { pickerOpen = true }
                    Button("Clear vault", role: .destructive) {
                        integrations.clearObsidianVault()
                    }
                } else {
                    Button {
                        pickerOpen = true
                    } label: {
                        Label("Pick vault folder…", systemImage: "folder.badge.plus")
                    }
                }
            } header: {
                Text("Vault")
            } footer: {
                Text("Tack stores each task as a markdown file inside a `tack/` folder at the root of the vault you pick. Files include YAML frontmatter so other tools (Dataview, Templater) can read them.")
            }

            Section {
                Button {
                    Task { await integrations.syncAll() }
                } label: {
                    Label("Sync now", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(integrations.obsidian == .notConfigured)

                if let last = integrations.lastSync {
                    Text("Last sync \(last.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(TK.Palette.textMuted)
                }
            } header: {
                Text("Sync")
            }
        }
        .navigationTitle("Obsidian")
        .sheet(isPresented: $pickerOpen) {
            FolderPickerSheet { url in
                integrations.setObsidianVault(url)
                pickerOpen = false
            }
        }
    }
}

// MARK: - Folder picker

#if os(iOS)
struct FolderPickerSheet: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
#else
struct FolderPickerSheet: View {
    let onPick: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: TK.Spacing.lg) {
            Text("Pick vault").font(.title2.weight(.semibold))
            Text("On macOS, click the button below and choose the vault folder in the dialog.")
                .multilineTextAlignment(.center)
                .foregroundStyle(TK.Palette.textMuted)
            Button("Open picker…") {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.allowsMultipleSelection = false
                panel.prompt = "Choose vault"
                if panel.runModal() == .OK, let url = panel.url {
                    onPick(url)
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Cancel") { dismiss() }
        }
        .padding(TK.Spacing.xl)
        .frame(width: 420)
    }
}
#endif
