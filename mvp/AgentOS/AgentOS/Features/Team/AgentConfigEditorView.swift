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

                    // Level 2: Model picker filtered to selected provider, plus "Custom…" option
                    Picker("Model", selection: modelPickerBinding) {
                        ForEach(config.provider.models, id: \.self) { model in
                            Text(model.displayName).tag(model.rawValue)
                        }
                        Divider()
                        Text("Custom…").tag("custom")
                    }

                    // Custom model text field — shown when not a known preset for current provider
                    if config.knownModel == nil || config.knownModel?.provider != config.provider {
                        TextField("e.g. gpt-oss:20b", text: $config.modelIdentifier)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption.monospaced())
                    }

                    HStack {
                        Spacer()
                        ModelTierBadge(modelIdentifier: config.modelIdentifier)
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
                    config.modelIdentifier = config.role.defaultModelIdentifier
                    config.provider = config.role.defaultProvider
                    config.temperature = 0.7
                    config.name = config.role.rawValue
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Done") {
                    // Prevent saving an empty custom model identifier
                    guard !config.modelIdentifier.trimmingCharacters(in: .whitespaces).isEmpty else {
                        config.modelIdentifier = config.role.defaultModelIdentifier
                        dismiss()
                        return
                    }
                    dismiss()
                }
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
                if config.knownModel?.provider != newProvider {
                    config.modelIdentifier = newProvider.defaultModelIdentifier
                }
            }
        )
    }

    // MARK: - Model Picker Binding

    /// Maps modelIdentifier to Picker selection: known preset → rawValue, custom → "custom".
    private var modelPickerBinding: Binding<String> {
        Binding(
            get: {
                guard let known = config.knownModel, known.provider == config.provider else {
                    return "custom"
                }
                return config.modelIdentifier
            },
            set: { value in
                if value == "custom" {
                    // Clear identifier so the user can type a custom name
                    config.modelIdentifier = ""
                } else {
                    config.modelIdentifier = value
                }
            }
        )
    }
}
