import SwiftUI
import SwiftData

struct ProviderListView: View {
    @Binding var selection: ProviderItem?
    @Query(sort: \CustomProvider.createdAt) var customProviders: [CustomProvider]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""

    private var filteredBuiltIn: [AIProvider] {
        guard !searchText.isEmpty else { return AIProvider.allCases.map { $0 } }
        return AIProvider.allCases.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredCustom: [CustomProvider] {
        guard !searchText.isEmpty else { return customProviders }
        return customProviders.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(selection: $selection) {
            Section("Built-in") {
                ForEach(filteredBuiltIn) { provider in
                    ProviderRow(
                        name: provider.displayName,
                        icon: iconName(for: provider),
                        hasSavedKey: KeychainHelper.hasKey(for: provider),
                        isCustom: false
                    )
                    .tag(ProviderItem.builtIn(provider))
                }
            }

            Section {
                ForEach(filteredCustom) { custom in
                    ProviderRow(
                        name: custom.name,
                        icon: "puzzlepiece.extension",
                        hasSavedKey: hasSavedKey(for: custom),
                        isCustom: true
                    )
                    .tag(ProviderItem.custom(custom.id))
                }
            } header: {
                HStack {
                    Text("Custom")
                    Spacer()
                    Button {
                        addCustomProvider()
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Filter providers")
        .listStyle(.sidebar)
    }

    private func iconName(for provider: AIProvider) -> String {
        switch provider {
        case .anthropic: return "brain.head.profile"
        case .openai:    return "sparkle"
        case .ollama:    return "desktopcomputer"
        case .qwen:      return "cloud"
        case .minimax:   return "waveform"
        case .gemini:    return "diamond"
        case .deepseek:  return "magnifyingglass.circle"
        case .groq:      return "bolt"
        case .mistral:   return "wind"
        case .cohere:    return "link"
        }
    }

    private func hasSavedKey(for custom: CustomProvider) -> Bool {
        !custom.requiresAPIKey
            || KeychainHelper.read(account: custom.keychainAccount) != nil
    }

    private func addCustomProvider() {
        let existingNames = Set(customProviders.map(\.name))
        var name = "New Provider"
        var counter = 2
        while existingNames.contains(name) {
            name = "New Provider \(counter)"
            counter += 1
        }
        let provider = CustomProvider(name: name)
        modelContext.insert(provider)
        selection = .custom(provider.id)
    }
}

// MARK: - ProviderRow

private struct ProviderRow: View {
    let name: String
    let icon: String
    let hasSavedKey: Bool
    let isCustom: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(.secondary)

            Text(name)
                .lineLimit(1)

            Spacer()

            if isCustom {
                Text("CUSTOM")
                    .font(.system(size: 9, weight: .semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            Circle()
                .fill(hasSavedKey ? .green : .gray.opacity(0.3))
                .frame(width: 8, height: 8)
        }
    }
}
