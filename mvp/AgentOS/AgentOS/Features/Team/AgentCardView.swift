import SwiftUI

struct AgentCardView: View {
    let config: AgentConfig
    var onEdit: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: icon + role
            HStack {
                Image(systemName: config.role.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(roleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name)
                        .font(.headline)
                    Text(config.role.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Model badge
            HStack {
                Image(systemName: "cpu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(config.modelDisplayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Temperature + Edit
            HStack {
                Text("Temp:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f", config.temperature))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Edit") { onEdit?() }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    private var roleColor: Color {
        switch config.role {
        case .ceo:        return .purple
        case .researcher: return .blue
        case .producer:   return .green
        case .qaReviewer: return .orange
        }
    }
}
