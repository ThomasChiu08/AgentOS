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
    @State private var baseURLInput: String = ""
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
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Base URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField(provider.defaultBaseURL, text: $baseURLInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                    .autocorrectionDisabled()
            }

            HStack(spacing: 8) {
                Button("Save") {
                    if provider.requiresAPIKey {
                        KeychainHelper[provider] = keyInput
                        isSaved = true
                    }
                    provider.customBaseURL = baseURLInput.isEmpty ? nil : baseURLInput
                }
                .disabled(provider.requiresAPIKey ? keyInput.isEmpty : baseURLInput.isEmpty)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button("Clear", role: .destructive) {
                    if provider.requiresAPIKey {
                        KeychainHelper[provider] = nil
                        keyInput = ""
                        isSaved = false
                    }
                    provider.customBaseURL = nil
                    baseURLInput = ""
                }
                .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
        .onAppear { loadStatus() }
    }

    private func loadStatus() {
        if provider.requiresAPIKey, KeychainHelper[provider] != nil {
            keyInput = "••••••••"
            isSaved = true
        }
        baseURLInput = provider.customBaseURL ?? ""
    }
}
