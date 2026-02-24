import Foundation
import SwiftData

// MARK: - StageStatus

enum StageStatus: String, Codable {
    case waiting, running, completed, failed, approved

    var label: String { rawValue.capitalized }

    var color: String {
        switch self {
        case .waiting: return "gray"
        case .running: return "blue"
        case .completed: return "orange"
        case .failed: return "red"
        case .approved: return "green"
        }
    }
}

// MARK: - Stage Model

@Model final class Stage {
    var id: UUID
    var agentRole: AgentRole
    var status: StageStatus
    var inputContext: String
    var outputContent: String
    var costUSD: Double
    var approved: Bool
    var qualityScore: Int?
    var recommendation: String?
    var position: Int
    var createdAt: Date

    var pipeline: Pipeline?
    @Relationship(deleteRule: .cascade) var artifacts: [Artifact]

    init(agentRole: AgentRole, position: Int, inputContext: String = "") {
        self.id = UUID()
        self.agentRole = agentRole
        self.status = .waiting
        self.inputContext = inputContext
        self.outputContent = ""
        self.costUSD = 0
        self.approved = false
        self.position = position
        self.createdAt = Date()
        self.artifacts = []
    }
}
