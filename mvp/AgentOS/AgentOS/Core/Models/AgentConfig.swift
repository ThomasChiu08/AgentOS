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

    var defaultModelIdentifier: String {
        switch self {
        case .ceo: return AIModel.claudeOpus.rawValue
        case .researcher, .producer, .qaReviewer: return AIModel.llama32.rawValue
        }
    }

    var defaultProvider: AIProvider {
        switch self {
        case .ceo: return .anthropic
        case .researcher, .producer, .qaReviewer: return .ollama
        }
    }

    var systemPromptTemplate: String {
        switch self {
        case .ceo:
            return """
            You are the CEO of a high-performance AI team. Your job is to help the user \
            accomplish their goals by orchestrating a team of specialized AI agents.

            When the user describes a task:
            1. Briefly acknowledge the goal in 1–2 sentences
            2. Output a pipeline plan as a JSON block using this exact schema:
            ```json
            {
              "pipeline": [
                { "role": "researcher", "task": "...", "researchURLs": [] },
                { "role": "producer", "task": "..." },
                { "role": "qaReviewer", "task": "..." }
              ]
            }
            ```
            3. After the JSON, provide a concise numbered summary for human readability

            Valid agent roles (use exactly these strings in the JSON):
            - researcher — web research, competitive analysis, fact-gathering
            - producer — writing, coding, content creation
            - qaReviewer — quality review, accuracy checking, improvement suggestions

            Example:
            User: "Write a cold email campaign for my SaaS product"
            Response:
            Great task! Here's my plan to craft a compelling cold email campaign:
            ```json
            {
              "pipeline": [
                { "role": "researcher", "task": "Research target audience and competitor email strategies", "researchURLs": [] },
                { "role": "producer", "task": "Write 3 email variations (welcome, follow-up, re-engagement)" },
                { "role": "qaReviewer", "task": "Check tone, personalization, and CTAs for effectiveness" }
              ]
            }
            ```
            1. Researcher → analyze target audience and gather competitive intel
            2. Producer → write 3 email variations
            3. QA Reviewer → review tone, personalization, and CTAs

            If the task is simple, propose just 1–2 stages. Don't over-engineer. Maximum 6 stages.
            """
        case .researcher:
            return """
            You are a Research Specialist. Your job is to gather accurate, up-to-date information.

            Always structure your output in this exact format:

            ## Research Brief: [Topic]

            ### Key Findings
            - Finding 1
            - Finding 2

            ### Analysis
            [2–3 paragraph synthesis]

            ### Sources
            - [Title](URL) — one sentence summary

            ### Recommended Next Steps
            [What the Producer should focus on based on this research]
            """
        case .producer:
            return """
            You are a Content Producer and Developer. Create high-quality deliverables.

            Structure your output as:

            ---
            [Main deliverable content here — document, code, copy, etc.]
            ---

            ## Decision Note
            Brief explanation of key choices made (tone, structure, format decisions).
            """
        case .qaReviewer:
            return """
            You are a Quality Assurance Reviewer. Evaluate the produced content critically.

            Always structure your output exactly as:

            ## QA Review

            **Quality Score: X/10**
            **Recommendation: APPROVE | REVISE | REJECT**

            ### Strengths
            - ...

            ### Issues
            - ...

            ### Specific Improvements Needed
            - ...
            """
        }
    }
}

// MARK: - AIProvider

enum AIProvider: String, Codable, CaseIterable, Identifiable {
    case anthropic
    case openai
    case ollama
    case qwen
    case minimax
    case gemini
    case deepseek
    case groq
    case mistral
    case cohere

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anthropic: return "Anthropic"
        case .openai:    return "OpenAI"
        case .ollama:    return "Ollama (Local)"
        case .qwen:      return "Qwen"
        case .minimax:   return "MiniMax"
        case .gemini:    return "Gemini"
        case .deepseek:  return "DeepSeek"
        case .groq:      return "Groq"
        case .mistral:   return "Mistral"
        case .cohere:    return "Cohere"
        }
    }

    /// Whether this provider requires an API key.
    var requiresAPIKey: Bool {
        self != .ollama
    }

    /// Keychain account identifier for storing this provider's API key.
    var keychainAccount: String {
        "agentos.\(rawValue).apikey"
    }

    /// The default model identifier for this provider.
    var defaultModelIdentifier: String {
        switch self {
        case .anthropic: return AIModel.claudeSonnet.rawValue
        case .openai:    return AIModel.gpt4o.rawValue
        case .ollama:    return AIModel.llama32.rawValue
        case .qwen:      return AIModel.qwenMax.rawValue
        case .minimax:   return AIModel.minimaxText01.rawValue
        case .gemini:    return AIModel.gemini20Flash.rawValue
        case .deepseek:  return AIModel.deepSeekChat.rawValue
        case .groq:      return AIModel.llama3370b.rawValue
        case .mistral:   return AIModel.mistralLarge.rawValue
        case .cohere:    return AIModel.commandRPlus.rawValue
        }
    }

    /// All models available for this provider.
    var models: [AIModel] {
        AIModel.allCases.filter { $0.provider == self }
    }
}

// MARK: - AIModel

enum AIModel: String, Codable, CaseIterable {
    // Anthropic (existing — rawValues unchanged for SwiftData compat)
    case claudeOpus   = "claude-opus-4-6"
    case claudeSonnet = "claude-sonnet-4-6"
    case claudeHaiku  = "claude-haiku-4-5-20251001"

    // OpenAI
    case gpt4o        = "gpt-4o"
    case gpt4oMini    = "gpt-4o-mini"
    case o1Preview    = "o1-preview"

    // Ollama
    case llama32      = "llama3.2"
    case mistral7b    = "mistral"
    case codellama    = "codellama"

    // Qwen
    case qwenMax      = "qwen-max"
    case qwenPlus     = "qwen-plus"

    // MiniMax
    case minimaxText01 = "MiniMax-Text-01"
    case minimax456    = "abab6.5s-chat"

    // Gemini
    case gemini20Flash = "gemini-2.0-flash"
    case gemini15Pro   = "gemini-1.5-pro"

    // DeepSeek
    case deepSeekChat     = "deepseek-chat"
    case deepSeekReasoner = "deepseek-reasoner"

    // Groq
    case llama3370b    = "llama-3.3-70b-versatile"
    case llama318b     = "llama-3.1-8b-instant"
    case mixtral8x7b   = "mixtral-8x7b-32768"

    // Mistral
    case mistralLarge = "mistral-large-latest"
    case mistralSmall = "mistral-small-latest"

    // Cohere
    case commandRPlus = "command-r-plus-08-2024"
    case commandR     = "command-r"

    var displayName: String {
        switch self {
        case .claudeOpus:      return "Claude Opus 4.6"
        case .claudeSonnet:    return "Claude Sonnet 4.6"
        case .claudeHaiku:     return "Claude Haiku 4.5"
        case .gpt4o:           return "GPT-4o"
        case .gpt4oMini:       return "GPT-4o Mini"
        case .o1Preview:       return "o1 Preview"
        case .llama32:         return "Llama 3.2"
        case .mistral7b:       return "Mistral 7B"
        case .codellama:       return "Code Llama"
        case .qwenMax:         return "Qwen Max"
        case .qwenPlus:        return "Qwen Plus"
        case .minimaxText01:   return "MiniMax Text 01"
        case .minimax456:      return "MiniMax 6.5s"
        case .gemini20Flash:   return "Gemini 2.0 Flash"
        case .gemini15Pro:     return "Gemini 1.5 Pro"
        case .deepSeekChat:    return "DeepSeek Chat"
        case .deepSeekReasoner: return "DeepSeek Reasoner"
        case .llama3370b:      return "Llama 3.3 70B"
        case .llama318b:       return "Llama 3.1 8B"
        case .mixtral8x7b:     return "Mixtral 8x7B"
        case .mistralLarge:    return "Mistral Large"
        case .mistralSmall:    return "Mistral Small"
        case .commandRPlus:    return "Command R+"
        case .commandR:        return "Command R"
        }
    }

    var provider: AIProvider {
        switch self {
        case .claudeOpus, .claudeSonnet, .claudeHaiku:
            return .anthropic
        case .gpt4o, .gpt4oMini, .o1Preview:
            return .openai
        case .llama32, .mistral7b, .codellama:
            return .ollama
        case .qwenMax, .qwenPlus:
            return .qwen
        case .minimaxText01, .minimax456:
            return .minimax
        case .gemini20Flash, .gemini15Pro:
            return .gemini
        case .deepSeekChat, .deepSeekReasoner:
            return .deepseek
        case .llama3370b, .llama318b, .mixtral8x7b:
            return .groq
        case .mistralLarge, .mistralSmall:
            return .mistral
        case .commandRPlus, .commandR:
            return .cohere
        }
    }
}

// MARK: - AgentConfig Model

@Model final class AgentConfig {
    var id: UUID
    var role: AgentRole
    var name: String
    var systemPrompt: String
    /// Stored model identity — persisted as String to support arbitrary/custom model names.
    var modelIdentifier: String
    var temperature: Double
    /// Stored provider identity — persisted as String for SwiftData lightweight migration.
    var providerName: String

    /// Computed provider — not persisted.
    var provider: AIProvider {
        get { AIProvider(rawValue: providerName) ?? .anthropic }
        set { providerName = newValue.rawValue }
    }

    /// Returns the known AIModel enum case if modelIdentifier matches a preset, nil for custom models.
    var knownModel: AIModel? { AIModel(rawValue: modelIdentifier) }

    /// Display name: preset model's name or the raw identifier for custom models.
    var modelDisplayName: String { knownModel?.displayName ?? modelIdentifier }

    init(role: AgentRole) {
        self.id = UUID()
        self.role = role
        self.name = role.rawValue
        self.systemPrompt = role.systemPromptTemplate
        self.modelIdentifier = role.defaultModelIdentifier
        self.temperature = 0.7
        self.providerName = role.defaultProvider.rawValue
    }
}
