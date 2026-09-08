import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var integrations: IntegrationHub
    @State private var appearance: Appearance = .system

    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    var body: some View {
        List {
            Section("Integrations") {
                NavigationLink {
                    NotionSettingsView()
                } label: {
                    IntegrationRow(
                        name: "Notion",
                        sfSymbol: "doc.text.magnifyingglass",
                        state: integrations.notion,
                        accent: .purple
                    )
                }
                NavigationLink {
                    ObsidianSettingsView()
                } label: {
                    IntegrationRow(
                        name: "Obsidian",
                        sfSymbol: "diamond",
                        state: integrations.obsidian,
                        accent: .indigo
                    )
                }
            }

            Section("Appearance") {
                Picker("Theme", selection: $appearance) {
                    ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0 (build 1)")
                LabeledContent("Sync engine", value: "Local + Notion + Obsidian")
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
