import SwiftUI
import SwiftData

/// Compact model selector for CEO Chat input bar.
/// Uses @Query for reactive SwiftData observation — stays in sync with AgentConfigEditorView changes.
struct ModelQuickPicker: View {
    @Environment(\.modelContext) private var modelContext
    // Fetch all, filter in-memory — avoids #Predicate rawValue issues with enum properties.
    @Query private var allConfigs: [AgentConfig]

    private var ceoConfig: AgentConfig? {
        allConfigs.first(where: { $0.role == .ceo })
    }

    private var modelIdentifier: String {
        ceoConfig?.modelIdentifier ?? AIModel.claudeOpus.rawValue
    }

    private var currentProvider: AIProvider {
        ceoConfig?.provider ?? .anthropic
    }

    private var displayName: String {
        AIModel(rawValue: modelIdentifier)?.displayName ?? modelIdentifier
    }

    var body: some View {
        Menu {
            // If current model is custom (unknown preset), show it disabled as a header
            if AIModel(rawValue: modelIdentifier) == nil && !modelIdentifier.isEmpty {
                Button(modelIdentifier) { }.disabled(true)
                Divider()
            }

            // Current provider's models (quick access)
            ForEach(currentProvider.models, id: \.self) { model in
                Button {
                    updateModel(to: model)
                } label: {
                    if model.rawValue == modelIdentifier {
                        Label(model.displayName, systemImage: "checkmark")
                    } else {
                        Text(model.displayName)
                    }
                }
            }

            Divider()

            // Other providers as submenus
            Menu("Switch Provider") {
                ForEach(AIProvider.allCases) { provider in
                    Menu(provider.displayName) {
                        ForEach(provider.models, id: \.self) { model in
                            Button(model.displayName) {
                                updateModel(to: model)
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .menuStyle(.borderlessButton)
    }

    private func updateModel(to model: AIModel) {
        if let config = ceoConfig {
            config.modelIdentifier = model.rawValue
            config.providerName = model.provider.rawValue
        } else {
            let config = AgentConfig(role: .ceo)
            config.modelIdentifier = model.rawValue
            config.providerName = model.provider.rawValue
            modelContext.insert(config)
        }
    }
}
