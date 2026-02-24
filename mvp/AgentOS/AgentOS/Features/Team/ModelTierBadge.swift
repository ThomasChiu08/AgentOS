import SwiftUI

struct ModelTierBadge: View {
    let modelIdentifier: String

    private var tier: (label: String, color: Color) {
        switch AIModel(rawValue: modelIdentifier) {
        case .claudeHaiku, .gpt4oMini, .llama318b, .llama32, .mistral7b, .gemini20Flash:
            return ("Speed", .green)
        case .claudeOpus, .o1Preview, .deepSeekReasoner:
            return ("Power", .purple)
        case nil:
            return ("Custom", .teal)
        default:
            return ("Balanced", .blue)
        }
    }

    var body: some View {
        Text(tier.label)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tier.color.opacity(0.15))
            .foregroundStyle(tier.color)
            .clipShape(Capsule())
    }
}
