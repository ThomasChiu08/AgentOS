import SwiftUI
import SwiftData

struct ProviderDetailView: View {
    let item: ProviderItem
    @Query(sort: \CustomProvider.createdAt) private var customProviders: [CustomProvider]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        switch item {
        case .builtIn(let provider):
            BuiltInDetailView(provider: provider)
        case .custom(let id):
            if let custom = customProviders.first(where: { $0.id == id }) {
                CustomDetailView(provider: custom)
                    .id(custom.id)
            } else {
                ContentUnavailableView(
                    "Provider Not Found",
                    systemImage: "questionmark.circle"
                )
            }
        }
    }
}

// MARK: - Built-in Provider Detail

private struct BuiltInDetailView: View {
    let provider: AIProvider

    @State private var keyInput = ""
    @State private var baseURLInput = ""
    @State private var isSaved = false
    @State private var showKey = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                Divider()
                if provider.requiresAPIKey {
                    apiKeySection
                }
                baseURLSection
                actionButtons
            }
            .padding(24)
        }
        .onAppear { loadStatus() }
        .onChange(of: provider) { loadStatus() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(provider.displayName)
                .font(.title)
                .fontWeight(.semibold)

            if !provider.requiresAPIKey {
                badge("Local", color: .blue)
            } else if isSaved {
                badge("Active", color: .green)
            } else {
                badge("No Key", color: .gray)
            }

            Spacer()
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("API Key")
                .font(.headline)

            HStack {
                Group {
                    if showKey {
                        TextField("Enter API key…", text: $keyInput)
                    } else {
                        SecureField("Enter API key…", text: $keyInput)
                    }
                }
                .textFieldStyle(.roundedBorder)

                Button {
                    showKey.toggle()
                } label: {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var baseURLSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Base URL")
                .font(.headline)

            TextField(provider.defaultBaseURL, text: $baseURLInput)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()

            Text("Leave blank to use the default endpoint.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Save") {
                save()
            }
            .buttonStyle(.borderedProminent)
            .disabled(provider.requiresAPIKey ? keyInput.isEmpty : false)

            Button("Clear", role: .destructive) {
                clear()
            }

            Spacer()
        }
    }

    private func save() {
        if provider.requiresAPIKey {
            if keyInput.hasPrefix("••") {
                isSaved = true
            } else if !keyInput.isEmpty {
                KeychainHelper[provider] = keyInput
                isSaved = true
            }
        }
        provider.customBaseURL = baseURLInput.isEmpty ? nil : baseURLInput
    }

    private func clear() {
        if provider.requiresAPIKey {
            KeychainHelper[provider] = nil
            keyInput = ""
            isSaved = false
        }
        provider.customBaseURL = nil
        baseURLInput = ""
    }

    private func loadStatus() {
        if provider.requiresAPIKey, KeychainHelper[provider] != nil {
            keyInput = "••••••••"
            isSaved = true
        } else {
            keyInput = ""
            isSaved = false
        }
        baseURLInput = provider.customBaseURL ?? ""
        showKey = false
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - Custom Provider Detail

private struct CustomDetailView: View {
    @Bindable var provider: CustomProvider
    @Environment(\.modelContext) private var modelContext

    @State private var keyInput = ""
    @State private var isSaved = false
    @State private var showKey = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                Divider()
                nameSection
                baseURLSection
                apiFormatSection
                if provider.requiresAPIKey {
                    apiKeySection
                }
                actionButtons
            }
            .padding(24)
        }
        .onAppear { loadStatus() }
        .alert("Delete Provider?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteProvider() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove \"\(provider.name)\" and its API key.")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(provider.name)
                .font(.title)
                .fontWeight(.semibold)

            badge("CUSTOM", color: .blue)

            if isSaved || !provider.requiresAPIKey {
                badge("Active", color: .green)
            }

            Spacer()

            Toggle("Enabled", isOn: $provider.isEnabled)
                .toggleStyle(.switch)
                .labelsHidden()

            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Provider Name")
                .font(.headline)
            TextField("e.g. My Local LLM", text: $provider.name)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var baseURLSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Base URL")
                .font(.headline)
            TextField("http://localhost:11434/v1", text: $provider.baseURL)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
            Text("The base URL for the API endpoint (without /chat/completions).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var apiFormatSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("API Format")
                .font(.headline)
            Picker("Format", selection: $provider.apiFormatRaw) {
                ForEach(CustomProvider.APIFormat.allCases, id: \.rawValue) { format in
                    Text(format.displayName).tag(format.rawValue)
                }
            }
            .labelsHidden()

            Toggle("Requires API Key", isOn: $provider.requiresAPIKey)
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("API Key")
                .font(.headline)

            HStack {
                Group {
                    if showKey {
                        TextField("Enter API key…", text: $keyInput)
                    } else {
                        SecureField("Enter API key…", text: $keyInput)
                    }
                }
                .textFieldStyle(.roundedBorder)

                Button {
                    showKey.toggle()
                } label: {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Save") {
                save()
            }
            .buttonStyle(.borderedProminent)

            Button("Clear Key", role: .destructive) {
                clearKey()
            }
            .disabled(!provider.requiresAPIKey)

            Spacer()
        }
    }

    private func save() {
        if provider.requiresAPIKey, !keyInput.isEmpty, !keyInput.hasPrefix("••") {
            KeychainHelper.save(keyInput, account: provider.keychainAccount)
            isSaved = true
        }
    }

    private func clearKey() {
        KeychainHelper.delete(account: provider.keychainAccount)
        keyInput = ""
        isSaved = false
    }

    private func deleteProvider() {
        KeychainHelper.delete(account: provider.keychainAccount)
        modelContext.delete(provider)
    }

    private func loadStatus() {
        if provider.requiresAPIKey,
           KeychainHelper.read(account: provider.keychainAccount) != nil {
            keyInput = "••••••••"
            isSaved = true
        } else {
            keyInput = ""
            isSaved = false
        }
        showKey = false
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
