import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var integrations: IntegrationHub
    @StateObject private var settings = AppSettings.shared

    private var appearanceBinding: Binding<String> {
        Binding(
            get: { settings.appearanceRaw },
            set: { settings.setAppearance(AppSettings.Appearance(rawValue: $0) ?? .system) }
        )
    }

    private var cloudSyncBinding: Binding<Bool> {
        Binding(
            get: { settings.enableCloudSync },
            set: { settings.enableCloudSync = $0 }
        )
    }

    var body: some View {
        List {
            Section {
                NavigationLink(destination: ObsidianSettingsView()) {
                    IntegrationRow(
                        name: "Obsidian",
                        sfSymbol: "diamond",
                        state: integrations.obsidian,
                        accent: .indigo
                    )
                }
            } header: {
                Text("Integrations")
            } footer: {
                Text("Tack stores each task as a markdown file inside a `tack/` folder at the root of the vault you pick. Files use YAML frontmatter so other tools — Dataview, Templater, Scripts — can read them.")
            }

            Section {
                Toggle(isOn: cloudSyncBinding) {
                    Label("iCloud sync (CloudKit)", systemImage: "icloud.fill")
                }
                LabeledContent("Last sync") {
                    Text(integrations.lastSync?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                        .foregroundStyle(TK.Palette.textMuted)
                }
            } header: {
                Text("Sync")
            } footer: {
                Text("iCloud sync requires setting up the CloudKit container in your Apple Developer account. Available in v1.1.")
            }

            Section("Appearance") {
                Picker("Theme", selection: appearanceBinding) {
                    ForEach(AppSettings.Appearance.allCases) { a in
                        Text(a.label).tag(a.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0 (build 1)")
                LabeledContent("Bundle", value: "app.tack.ios")
                LabeledContent("Engine", value: "SwiftData + Obsidian")
            }
        }
        .navigationTitle("Settings")
        .background(TK.Palette.bgDeep.ignoresSafeArea())
    }
}

struct IntegrationRow: View {
    let name: String
    let sfSymbol: String
    let state: IntegrationHub.IntegrationState
    let accent: Color

    var body: some View {
        HStack {
            Image(systemName: sfSymbol)
                .foregroundStyle(accent)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.body)
                Text(state.label)
                    .font(.caption)
                    .foregroundStyle(color(for: state))
            }
            Spacer()
            Circle()
                .fill(color(for: state))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }

    private func color(for state: IntegrationHub.IntegrationState) -> Color {
        switch state {
        case .ok:             return TK.Palette.success
        case .syncing:        return TK.Palette.warning
        case .error:          return TK.Palette.danger
        case .disconnected,
             .notConfigured:  return TK.Palette.textTertiary
        }
    }
}
