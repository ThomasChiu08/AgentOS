import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("yoloModeDefault") private var yoloModeDefault: Bool = false

    @Query var projects: [Project]

    private var totalCost: Double {
        projects.compactMap { $0.pipeline?.totalCostUSD }.reduce(0, +)
    }

    var body: some View {
        Form {
            Section("AI Provider API Keys") {
                ForEach(AIProvider.allCases) { provider in
                    ProviderKeyRow(provider: provider)
                }
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
}

// MARK: - ProviderKeyRow

private struct ProviderKeyRow: View {
    let provider: AIProvider

    @State private var keyInput: String = ""
    @State private var isSaved = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(provider.displayName)
                    .fontWeight(.medium)
                Spacer()
                if !provider.requiresAPIKey {
                    Label("Local — no key needed", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                } else if isSaved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }
            }

            if provider.requiresAPIKey {
                SecureField("API key…", text: $keyInput)
                    .onAppear { loadKeyStatus() }

                HStack(spacing: 8) {
                    Button("Save") {
                        KeychainHelper[provider] = keyInput
                        isSaved = true
                    }
                    .disabled(keyInput.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Clear", role: .destructive) {
                        KeychainHelper[provider] = nil
                        keyInput = ""
                        isSaved = false
                    }
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func loadKeyStatus() {
        if KeychainHelper[provider] != nil {
            keyInput = "••••••••"
            isSaved = true
        }
    }
}
