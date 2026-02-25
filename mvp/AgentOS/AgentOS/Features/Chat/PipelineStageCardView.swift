import SwiftUI

struct PipelineStageCardView: View {
    let stage: ParsedStage
    let index: Int

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: stage.role.icon)
                .font(.callout)
                .foregroundStyle(roleColor)
                .frame(width: 28, height: 28)
                .background(roleColor.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(stage.role.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("Step \(index + 1)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(stage.task)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                if !stage.researchURLs.isEmpty {
                    Label("\(stage.researchURLs.count) URLs", systemImage: "link")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(roleColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var roleColor: Color {
        switch stage.role {
        case .researcher:  return .blue
        case .producer:    return .orange
        case .qaReviewer:  return .green
        case .ceo:         return .purple
        }
    }
}
