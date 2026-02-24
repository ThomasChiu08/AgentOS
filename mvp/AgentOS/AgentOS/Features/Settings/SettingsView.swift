import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var apiKeyInput: String = ""
    @State private var apiKeySaved = false
    @AppStorage("yoloModeDefault") private var yoloModeDefault: Bool = false

    @Query var projects: [Project]

    private var totalCost: Double {
        projects.compactMap { $0.pipeline?.totalCostUSD }.reduce(0, +)
    }

    var body: some View {
        Form {
            Section("Anthropic API Key") {
                SecureField("sk-ant-…", text: $apiKeyInput)
                    .onAppear { loadKeyStatus() }

                HStack {
                    Button("Save Key") {
                        KeychainHelper.apiKey = apiKeyInput
                        apiKeySaved = true
                    }
                    .disabled(apiKeyInput.isEmpty)

                    if apiKeySaved {
                        Label("Saved securely in Keychain", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }

                Button("Clear Key", role: .destructive) {
                    KeychainHelper.apiKey = nil
                    apiKeyInput = ""
                    apiKeySaved = false
                }
                .controlSize(.small)
            }

            Section("Defaults") {
                Toggle("Yolo Mode by default", isOn: $yoloModeDefault)
                Text("Skips human approval gates — stages run automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Usage") {
                LabeledContent("Total Projects", value: "\(projects.count)")
                LabeledContent("Total Cost", value: String(format: "$%.4f", totalCost))
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }

    private func loadKeyStatus() {
        if KeychainHelper.apiKey != nil {
            apiKeyInput = "••••••••"
            apiKeySaved = true
        }
    }
}
