import SwiftUI

struct AgentConfigEditorView: View {
    @Bindable var config: AgentConfig
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Identity") {
                    TextField("Display Name", text: $config.name)
                }

                Section("Provider & Model") {
                    // Level 1: Provider picker
                    Picker("Provider", selection: providerBinding) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }

                    // Level 2: Model picker filtered to selected provider
                    Picker("Model", selection: $config.model) {
                        ForEach(config.provider.models, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }

                    HStack {
                        Spacer()
                        ModelTierBadge(model: config.model)
                    }

                    // Warning if no key is saved for this provider
                    if !KeychainHelper.hasKey(for: config.provider) {
                        Label(
                            "No API key saved for \(config.provider.displayName). Add it in Settings.",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.orange)
                        .font(.caption)
                    }

                    HStack {
                        Text("Temperature")
                        Slider(value: $config.temperature, in: 0...1, step: 0.1)
                        Text(String(format: "%.1f", config.temperature))
                            .monospacedDigit()
                            .frame(width: 30)
                    }
                }

                Section("System Prompt") {
                    TextEditor(text: $config.systemPrompt)
                        .frame(minHeight: 120)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .formStyle(.grouped)

            // Toolbar
            HStack {
                Button("Reset to Default") {
                    config.systemPrompt = config.role.systemPromptTemplate
                    config.model = config.role.defaultModel
                    config.provider = .anthropic
                    config.temperature = 0.7
                    config.name = config.role.rawValue
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 420)
    }

    // MARK: - Provider Binding

    /// When the provider changes, auto-snap the model to the new provider's default
    /// if the current model doesn't belong to the new provider.
    private var providerBinding: Binding<AIProvider> {
        Binding(
            get: { config.provider },
            set: { newProvider in
                config.provider = newProvider
                if config.model.provider != newProvider {
                    config.model = newProvider.defaultModel
                }
            }
        )
    }
}
