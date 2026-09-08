import SwiftUI

struct NotionSettingsView: View {
    @EnvironmentObject private var integrations: IntegrationHub
    @State private var authInFlight = false
    @State private var databases: [NotionDatabase] = []
    @State private var selectedDB: String?
    @State private var statusText: String = ""

    var body: some View {
        Form {
            Section {
                if integrations.notion == .ok {
                    Label("Connected to Notion", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(TK.Palette.success)
                    Button("Disconnect", role: .destructive) {
                        integrations.notionDisconnect()
                    }
                } else {
                    Button {
                        Task { await authenticate() }
                    } label: {
                        HStack {
                            Image(systemName: "link")
                            Text(authInFlight ? "Opening browser…" : "Sign in with Notion")
                        }
                    }
                    .disabled(authInFlight)
                }
            } header: {
                Text("Account")
            } footer: {
                Text("Notion uses OAuth. We don't store any personal data outside the integration token.")
            }

            if integrations.notion == .ok {
                Section("Database") {
                    if databases.isEmpty {
                        Button("Load databases") {
                            Task { await loadDatabases() }
                        }
                    } else {
                        ForEach(databases) { db in
                            Button {
                                selectedDB = db.id
                                integrations.notionPickDatabase(db.id)
                                statusText = "Linked \"\(db.displayTitle)\""
                            } label: {
                                HStack {
                                    Image(systemName: "tablecells")
                                    Text(db.displayTitle)
                                    Spacer()
                                    if selectedDB == db.id {
                                        Image(systemName: "checkmark").foregroundStyle(TK.Palette.accent)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if !statusText.isEmpty {
                        Text(statusText).font(.caption).foregroundStyle(TK.Palette.textMuted)
                    }
                }
            }
        }
        .navigationTitle("Notion")
    }

    private func authenticate() async {
        authInFlight = true
        defer { authInFlight = false }
        guard let url = await integrations.notionAuthURL() else { return }
        #if os(iOS)
        await UIApplication.shared.open(url)
        #else
        NSWorkspace.shared.open(url)
        #endif
    }

    private func loadDatabases() async {
        let client = NotionClient()
        do {
            databases = try await client.listDatabases()
        } catch {
            statusText = error.localizedDescription
        }
    }
}
