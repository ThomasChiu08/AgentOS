import SwiftUI

struct StageCardView: View {
    let stage: Stage
    var onApprove: (() -> Void)?
    var onReject: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status indicator + agent icon
            VStack(spacing: 4) {
                Image(systemName: stage.agentRole.icon)
                    .font(.title3)
                    .foregroundStyle(statusColor)
                    .frame(width: 32, height: 32)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Circle())

                if stage.status == .running {
                    ProgressView().scaleEffect(0.6)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(stage.agentRole.rawValue)
                        .font(.headline)
                    Spacer()
                    StatusBadge(status: stage.status)
                    if stage.costUSD > 0 {
                        Text(String(format: "$%.4f", stage.costUSD))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if !stage.outputContent.isEmpty {
                    Text(stage.outputContent.truncated(to: 120))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }

                if stage.status == .completed {
                    HStack(spacing: 8) {
                        Button("Approve") { onApprove?() }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                            .controlSize(.small)
                        Button("Reject") { onReject?() }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(statusColor.opacity(stage.status == .running ? 0.6 : 0.15), lineWidth: 1)
        )
    }

    private var statusColor: Color {
        switch stage.status {
        case .waiting:   return .secondary
        case .running:   return .blue
        case .completed: return .orange
        case .failed:    return .red
        case .approved:  return .green
        }
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: StageStatus

    var body: some View {
        Text(status.label)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch status {
        case .waiting:   return .secondary
        case .running:   return .blue
        case .completed: return .orange
        case .failed:    return .red
        case .approved:  return .green
        }
    }
}
