import Foundation
import SwiftData

// MARK: - ProjectStatus

enum ProjectStatus: String, Codable {
    case idle, running, paused, completed, failed

    var label: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .idle: return "clock"
        case .running: return "play.circle"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
}

// MARK: - Project Model

@Model final class Project {
    var id: UUID
    var title: String
    var goal: String
    var status: ProjectStatus
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var pipeline: Pipeline?

    init(title: String, goal: String = "") {
        self.id = UUID()
        self.title = title
        self.goal = goal
        self.status = .idle
        self.createdAt = Date()
    }
}
