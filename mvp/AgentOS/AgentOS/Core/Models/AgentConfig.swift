import Foundation
import SwiftData

// MARK: - AgentRole

enum AgentRole: String, Codable, CaseIterable {
    case ceo = "CEO"
    case researcher = "Researcher"
    case producer = "Producer"
    case qaReviewer = "QA Reviewer"

    var icon: String {
        switch self {
        case .ceo: return "crown"
        case .researcher: return "magnifyingglass"
        case .producer: return "pencil"
        case .qaReviewer: return "checkmark.seal"
        }
    }

    var defaultModel: AIModel {
        switch self {
        case .ceo: return .claudeOpus
        case .researcher, .producer, .qaReviewer: return .claudeSonnet
        }
    }

    var systemPromptTemplate: String {
        switch self {
        case .ceo:
            return "You are the CEO of a virtual AI team. Your job is to understand the user's goal and decompose it into a clear, sequential pipeline of tasks. Each task should be assigned to the most appropriate agent role."
        case .researcher:
            return "You are a research specialist. Your job is to gather accurate, up-to-date information on the given topic using web search. Synthesize findings into clear, structured notes."
        case .producer:
            return "You are a content producer and developer. Your job is to create high-quality deliverables — documents, code, reports — based on the research and brief provided."
        case .qaReviewer:
            return "You are a quality assurance reviewer. Your job is to critically evaluate the produced content for accuracy, completeness, clarity, and quality. Provide specific improvement suggestions."
        }
    }
}

// MARK: - AIModel

enum AIModel: String, Codable, CaseIterable {
    case claudeOpus = "claude-opus-4-6"
    case claudeSonnet = "claude-sonnet-4-6"
    case claudeHaiku = "claude-haiku-4-5-20251001"

    var displayName: String {
        switch self {
        case .claudeOpus: return "Claude Opus 4.6"
        case .claudeSonnet: return "Claude Sonnet 4.6"
        case .claudeHaiku: return "Claude Haiku 4.5"
        }
    }
}

// MARK: - AgentConfig Model

@Model final class AgentConfig {
    var id: UUID
    var role: AgentRole
    var name: String
    var systemPrompt: String
    var model: AIModel
    var temperature: Double

    init(role: AgentRole) {
        self.id = UUID()
        self.role = role
        self.name = role.rawValue
        self.systemPrompt = role.systemPromptTemplate
        self.model = role.defaultModel
        self.temperature = 0.7
    }
}
