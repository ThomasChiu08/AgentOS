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

                Section("Model") {
                    Picker("Model", selection: $config.model) {
                        ForEach(AIModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    .pickerStyle(.segmented)

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
        .frame(minWidth: 500, minHeight: 400)
    }
}
