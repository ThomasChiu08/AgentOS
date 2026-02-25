import Foundation
import SwiftData

@Model final class CustomProvider {
    var id: UUID
    var name: String
    var baseURL: String
    var requiresAPIKey: Bool
    var apiFormatRaw: String
    var isEnabled: Bool
    var createdAt: Date

    var apiFormat: APIFormat {
        get { APIFormat(rawValue: apiFormatRaw) ?? .chatCompletions }
        set { apiFormatRaw = newValue.rawValue }
    }

    enum APIFormat: String, Codable, CaseIterable {
        case chatCompletions
        case anthropicMessages

        var displayName: String {
            switch self {
            case .chatCompletions: return "Chat Completions (OpenAI-compatible)"
            case .anthropicMessages: return "Anthropic Messages"
            }
        }
    }

    var keychainAccount: String {
        "agentos.custom.\(id.uuidString).apikey"
    }

    init(
        name: String = "New Provider",
        baseURL: String = "http://localhost:11434/v1",
        requiresAPIKey: Bool = true,
        apiFormat: APIFormat = .chatCompletions,
        isEnabled: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.baseURL = baseURL
        self.requiresAPIKey = requiresAPIKey
        self.apiFormatRaw = apiFormat.rawValue
        self.isEnabled = isEnabled
        self.createdAt = Date()
    }
}
