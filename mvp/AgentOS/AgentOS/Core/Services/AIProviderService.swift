import Foundation

// MARK: - AIProvider URL Extension

extension AIProvider {
    var chatCompletionURL: URL {
        switch self {
        case .anthropic:
            return URL(string: "https://api.anthropic.com/v1/messages")!
        case .openai:
            return URL(string: "https://api.openai.com/v1/chat/completions")!
        case .ollama:
            return URL(string: "http://localhost:11434/v1/chat/completions")!
        case .qwen:
            return URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")!
        case .minimax:
            return URL(string: "https://api.minimax.chat/v1/chat/completions")!
        case .gemini:
            return URL(string: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")!
        case .deepseek:
            return URL(string: "https://api.deepseek.com/v1/chat/completions")!
        case .groq:
            return URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        case .mistral:
            return URL(string: "https://api.mistral.ai/v1/chat/completions")!
        case .cohere:
            return URL(string: "https://api.cohere.com/compatibility/v1/chat/completions")!
        }
    }
}

// MARK: - AIModel Pricing Extension

extension AIModel {
    var inputPricePerMillion: Double {
        switch self {
        // Anthropic
        case .claudeOpus:          return 15.00
        case .claudeSonnet:        return 3.00
        case .claudeHaiku:         return 0.80
        // OpenAI
        case .gpt4o:               return 2.50
        case .gpt4oMini:           return 0.15
        case .o1Preview:           return 15.00
        // Ollama (local — free)
        case .llama32, .mistral7b, .codellama: return 0.00
        // Qwen
        case .qwenMax:             return 0.40
        case .qwenPlus:            return 0.08
        // MiniMax
        case .minimaxText01:       return 0.20
        case .minimax456:          return 0.10
        // Gemini
        case .gemini20Flash:       return 0.075
        case .gemini15Pro:         return 1.25
        // DeepSeek
        case .deepSeekChat:        return 0.07
        case .deepSeekReasoner:    return 0.55
        // Groq (hosted, priced per token)
        case .llama3370b:          return 0.59
        case .llama318b:           return 0.05
        case .mixtral8x7b:         return 0.24
        // Mistral
        case .mistralLarge:        return 2.00
        case .mistralSmall:        return 0.20
        // Cohere
        case .commandRPlus:        return 2.50
        case .commandR:            return 0.15
        }
    }

    var outputPricePerMillion: Double {
        switch self {
        // Anthropic
        case .claudeOpus:          return 75.00
        case .claudeSonnet:        return 15.00
        case .claudeHaiku:         return 4.00
        // OpenAI
        case .gpt4o:               return 10.00
        case .gpt4oMini:           return 0.60
        case .o1Preview:           return 60.00
        // Ollama (local — free)
        case .llama32, .mistral7b, .codellama: return 0.00
        // Qwen
        case .qwenMax:             return 1.20
        case .qwenPlus:            return 0.24
        // MiniMax
        case .minimaxText01:       return 0.20
        case .minimax456:          return 0.10
        // Gemini
        case .gemini20Flash:       return 0.30
        case .gemini15Pro:         return 5.00
        // DeepSeek
        case .deepSeekChat:        return 0.27
        case .deepSeekReasoner:    return 2.19
        // Groq
        case .llama3370b:          return 0.79
        case .llama318b:           return 0.08
        case .mixtral8x7b:         return 0.24
        // Mistral
        case .mistralLarge:        return 6.00
        case .mistralSmall:        return 0.60
        // Cohere
        case .commandRPlus:        return 10.00
        case .commandR:            return 0.60
        }
    }
}

// MARK: - Protocol

protocol AIProviderProtocol: Sendable {
    func complete(
        systemPrompt: String,
        userMessage: String,
        modelIdentifier: String,
        temperature: Double
    ) async throws -> AIResponse
}

// MARK: - Response

struct AIResponse: Sendable {
    let content: String
    let inputTokens: Int
    let outputTokens: Int
    let costUSD: Double
}

// MARK: - Errors

enum AIProviderError: LocalizedError {
    case missingAPIKey(AIProvider)
    case invalidResponse
    case rateLimited
    case timeout
    case serverError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "API key not set for \(provider.displayName). Open Settings to add your key."
        case .invalidResponse:
            return "Unexpected response from AI provider."
        case .rateLimited:
            return "Rate limit reached. Please wait and try again."
        case .timeout:
            return "Request timed out. The AI provider may be slow — try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

// MARK: - ClaudeProvider (Anthropic native format)

struct ClaudeProvider: AIProviderProtocol {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let anthropicVersion = "2023-06-01"

    func complete(
        systemPrompt: String,
        userMessage: String,
        modelIdentifier: String,
        temperature: Double
    ) async throws -> AIResponse {
        guard let apiKey = KeychainHelper[.anthropic], !apiKey.isEmpty else {
            throw AIProviderError.missingAPIKey(.anthropic)
        }

        var request = URLRequest(url: endpoint, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": modelIdentifier,
            "max_tokens": 4096,
            "temperature": temperature,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userMessage]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw AIProviderError.timeout
        } catch {
            throw AIProviderError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        switch http.statusCode {
        case 200:
            return try parseAnthropicResponse(data: data, modelIdentifier: modelIdentifier)
        case 401:
            throw AIProviderError.missingAPIKey(.anthropic)
        case 429:
            throw AIProviderError.rateLimited
        default:
            throw AIProviderError.serverError(http.statusCode)
        }
    }

    private func parseAnthropicResponse(data: Data, modelIdentifier: String) throws -> AIResponse {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let contentArr = json["content"] as? [[String: Any]],
            let text = contentArr.first?["text"] as? String,
            let usage = json["usage"] as? [String: Any],
            let inputTokens = usage["input_tokens"] as? Int,
            let outputTokens = usage["output_tokens"] as? Int
        else {
            throw AIProviderError.invalidResponse
        }

        let knownModel = AIModel(rawValue: modelIdentifier)
        let cost = (Double(inputTokens) / 1_000_000) * (knownModel?.inputPricePerMillion ?? 0)
                 + (Double(outputTokens) / 1_000_000) * (knownModel?.outputPricePerMillion ?? 0)

        return AIResponse(
            content: text,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            costUSD: cost
        )
    }
}

// MARK: - OpenAICompatibleProvider

/// Handles all 9 non-Anthropic providers via the OpenAI-compatible /v1/chat/completions endpoint.
struct OpenAICompatibleProvider: AIProviderProtocol {
    let provider: AIProvider

    func complete(
        systemPrompt: String,
        userMessage: String,
        modelIdentifier: String,
        temperature: Double
    ) async throws -> AIResponse {
        // Ollama doesn't require a key; all others do.
        if provider.requiresAPIKey {
            guard let key = KeychainHelper[provider], !key.isEmpty else {
                throw AIProviderError.missingAPIKey(provider)
            }
        }

        var request = URLRequest(url: provider.chatCompletionURL, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if provider.requiresAPIKey, let key = KeychainHelper[provider] {
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "model": modelIdentifier,
            "temperature": temperature,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user",   "content": userMessage]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw AIProviderError.timeout
        } catch {
            throw AIProviderError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        switch http.statusCode {
        case 200:
            return try parseOpenAIResponse(data: data, modelIdentifier: modelIdentifier)
        case 401:
            throw AIProviderError.missingAPIKey(provider)
        case 429:
            throw AIProviderError.rateLimited
        default:
            throw AIProviderError.serverError(http.statusCode)
        }
    }

    private func parseOpenAIResponse(data: Data, modelIdentifier: String) throws -> AIResponse {
        // OpenAI response shape:
        // { "choices": [{"message": {"content": "..."}}],
        //   "usage": {"prompt_tokens": N, "completion_tokens": N} }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let text = message["content"] as? String
        else {
            throw AIProviderError.invalidResponse
        }

        var inputTokens = 0
        var outputTokens = 0
        if let usage = json["usage"] as? [String: Any] {
            inputTokens  = usage["prompt_tokens"]     as? Int ?? 0
            outputTokens = usage["completion_tokens"] as? Int ?? 0
        }

        let knownModel = AIModel(rawValue: modelIdentifier)
        let cost = (Double(inputTokens) / 1_000_000) * (knownModel?.inputPricePerMillion ?? 0)
                 + (Double(outputTokens) / 1_000_000) * (knownModel?.outputPricePerMillion ?? 0)

        return AIResponse(
            content: text,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            costUSD: cost
        )
    }
}

// MARK: - AIProviderFactory

enum AIProviderFactory {
    static func make(for provider: AIProvider) -> any AIProviderProtocol {
        provider == .anthropic
            ? ClaudeProvider()
            : OpenAICompatibleProvider(provider: provider)
    }
}
