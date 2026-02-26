import SwiftUI
import SwiftData

struct TeamView: View {
    @Query var configs: [AgentConfig]
    @Environment(\.modelContext) var modelContext
    @State private var editingConfig: AgentConfig?

    private let columns = [GridItem(.flexible(minimum: 200)), GridItem(.flexible(minimum: 200))]

    var body: some View {
        Group {
            if configs.isEmpty {
                ContentUnavailableView {
                    Label("Setting Up Team", systemImage: "person.3")
                } description: {
                    Text("Your AI team is being configured…")
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(configs) { config in
                                AgentCardView(config: config) {
                                    editingConfig = config
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Team")
        .onAppear { seedDefaultsIfNeeded() }
        .sheet(item: $editingConfig) { config in
            AgentConfigEditorView(config: config)
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MVP Team — \(configs.count) Agents")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("V1 will add Editor, Operations, and Finance agents.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - First Launch Seed

    private func seedDefaultsIfNeeded() {
        guard configs.isEmpty else { return }
        for role in AgentRole.allCases {
            modelContext.insert(AgentConfig(role: role))
        }
    }
}
