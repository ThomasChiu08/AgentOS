import SwiftUI
import SwiftData

/// Compact model selector for CEO Chat input bar.
/// Uses @Query for reactive SwiftData observation — stays in sync with AgentConfigEditorView changes.
struct ModelQuickPicker: View {
    @Environment(\.modelContext) private var modelContext
    // Fetch all, filter in-memory — avoids #Predicate rawValue issues with enum properties.
    @Query private var allConfigs: [AgentConfig]
    @State private var showingCustomModelInput = false
    @State private var customModelInput = ""
    @State private var ollamaModels: [String] = []

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

            // Show locally discovered Ollama models when using Ollama provider
            if currentProvider == .ollama, !ollamaModels.isEmpty {
                Divider()
                Section("Local Models") {
                    ForEach(ollamaModels, id: \.self) { name in
                        Button {
                            updateCustomModel(name)
                        } label: {
                            if name == modelIdentifier {
                                Label(name, systemImage: "checkmark")
                            } else {
                                Text(name)
                            }
                        }
                    }
                }
            }

            Button {
                showingCustomModelInput = true
            } label: {
                Label("Custom model…", systemImage: "pencil")
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
        .task(id: currentProvider) {
            guard currentProvider == .ollama else {
                ollamaModels = []
                return
            }
            let baseURL = AIProvider.ollama.customBaseURL ?? "http://localhost:11434"
            // Strip /v1 suffix — OllamaHealthCheck uses the native /api/tags endpoint
            let cleanBase = baseURL.replacingOccurrences(of: "/v1", with: "")
            ollamaModels = await OllamaHealthCheck.availableModelNames(baseURL: cleanBase)
        }
        .alert("Custom Model", isPresented: $showingCustomModelInput) {
            TextField("e.g. gpt-oss:20b", text: $customModelInput)
            Button("Use") {
                let trimmed = customModelInput.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { updateCustomModel(trimmed) }
                customModelInput = ""
            }
            Button("Cancel", role: .cancel) {
                customModelInput = ""
            }
        } message: {
            Text("Enter the exact model identifier from your provider.")
        }
    }

    private func updateCustomModel(_ identifier: String) {
        // Custom identifiers are local Ollama models — always route to Ollama endpoint.
        let targetProvider = AIProvider.ollama.rawValue
        if let config = ceoConfig {
            config.modelIdentifier = identifier
            config.providerName = targetProvider
        } else {
            let config = AgentConfig(role: .ceo)
            config.modelIdentifier = identifier
            config.providerName = targetProvider
            modelContext.insert(config)
        }
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
