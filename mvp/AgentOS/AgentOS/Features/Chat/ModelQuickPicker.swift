import SwiftUI
import SwiftData

/// Compact model selector for CEO Chat input bar.
/// Reads and writes the CEO agent's model directly in SwiftData.
struct ModelQuickPicker: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentModel: AIModel = .claudeOpus

    var body: some View {
        Menu {
            ForEach(AIModel.allCases.filter { $0.provider == currentModel.provider }, id: \.self) { model in
                Button(model.displayName) {
                    updateModel(to: model)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(currentModel.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .menuStyle(.borderlessButton)
        .onAppear { loadCurrentModel() }
    }

    private func loadCurrentModel() {
        let roleRaw = AgentRole.ceo.rawValue
        var descriptor = FetchDescriptor<AgentConfig>(
            predicate: #Predicate { $0.role.rawValue == roleRaw }
        )
        descriptor.fetchLimit = 1
        if let saved = try? modelContext.fetch(descriptor).first {
            currentModel = saved.model
        }
    }

    private func updateModel(to model: AIModel) {
        currentModel = model
        let roleRaw = AgentRole.ceo.rawValue
        var descriptor = FetchDescriptor<AgentConfig>(
            predicate: #Predicate { $0.role.rawValue == roleRaw }
        )
        descriptor.fetchLimit = 1
        if let config = try? modelContext.fetch(descriptor).first {
            config.model = model
        } else {
            let config = AgentConfig(role: .ceo)
            config.model = model
            modelContext.insert(config)
        }
    }
}
