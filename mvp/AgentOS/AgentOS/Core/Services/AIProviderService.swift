import Foundation
import os

// MARK: - String Helpers

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}

// MARK: - AIProvider URL Extension

extension AIProvider {
    /// UserDefaults key for a custom base URL override for this provider.
    private var baseURLDefaultsKey: String { "agentos.\(rawValue).baseURL" }

    /// The custom base URL set by the user in Settings, or nil if using the default.
    var customBaseURL: String? {
        get { UserDefaults.standard.string(forKey: baseURLDefaultsKey)?.nonEmpty }
        nonmutating set {
            if let value = newValue, !value.isEmpty {
                UserDefaults.standard.set(value, forKey: baseURLDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: baseURLDefaultsKey)
            }
        }
    }

    /// The default base URL (without path) shown as placeholder in Settings.
    var defaultBaseURL: String {
        switch self {
        case .anthropic: return "https://api.anthropic.com/v1"
        case .openai:    return "https://api.openai.com/v1"
        case .ollama:    return "http://localhost:11434/v1"
        case .qwen:      return "https://dashscope.aliyuncs.com/compatible-mode/v1"
        case .minimax:   return "https://api.minimax.chat/v1"
        case .gemini:    return "https://generativelanguage.googleapis.com/v1beta/openai"
        case .deepseek:  return "https://api.deepseek.com/v1"
        case .groq:      return "https://api.groq.com/openai/v1"
        case .mistral:   return "https://api.mistral.ai/v1"
        case .cohere:    return "https://api.cohere.com/compatibility/v1"
        }
    }

    var chatCompletionURL: URL {
        // Prefer the user's custom base URL when set.
        if let base = customBaseURL,
           let url = URL(string: base.trimmingCharacters(in: .init(charactersIn: "/")) + "/chat/completions") {
            return url
        }
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
            return "API key not set for \(provider.displayName). Go to Settings → API Keys to add it."
        case .invalidResponse:
            return "Unexpected response from AI provider."
        case .rateLimited:
            return "Rate limit reached. Please wait a moment and try again."
        case .timeout:
            return "Request timed out. The model may still be loading — try again in a moment."
        case .serverError(let code):
            if code == 401 {
                return "API key invalid or expired. Check your key in Settings."
            }
            return "Server error (\(code)). Please try again."
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

// MARK: - ClaudeProvider (Anthropic native format)

struct ClaudeProvider: AIProviderProtocol {
    private let anthropicVersion = "2023-06-01"
    private let logger = Logger(subsystem: "com.thomas.agentos", category: "ClaudeProvider")

    func complete(
        systemPrompt: String,
        userMessage: String,
        modelIdentifier: String,
        temperature: Double
    ) async throws -> AIResponse {
        guard let apiKey = KeychainHelper[.anthropic], !apiKey.isEmpty else {
            throw AIProviderError.missingAPIKey(.anthropic)
        }

        // Respect custom base URL override if set, otherwise use the default.
        let endpoint = AIProvider.anthropic.customBaseURL
            .flatMap { URL(string: $0.trimmingCharacters(in: .init(charactersIn: "/")) + "/messages") }
            ?? URL(string: "https://api.anthropic.com/v1/messages")!

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

        logger.debug("Sending request to \(endpoint.absoluteString) model=\(modelIdentifier)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            logger.error("Request timed out: \(endpoint.absoluteString)")
            throw AIProviderError.timeout
        } catch {
            logger.error("Network error: \(error.localizedDescription) url=\(endpoint.absoluteString)")
            throw AIProviderError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        logger.debug("Response status=\(http.statusCode) from \(endpoint.absoluteString)")

        switch http.statusCode {
        case 200:
            return try parseAnthropicResponse(data: data, modelIdentifier: modelIdentifier)
        case 401:
            logger.warning("Authentication failed for Anthropic")
            throw AIProviderError.missingAPIKey(.anthropic)
        case 429:
            logger.warning("Rate limited by Anthropic")
            throw AIProviderError.rateLimited
        default:
            logger.error("Server error \(http.statusCode) from Anthropic")
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
    private let logger = Logger(subsystem: "com.thomas.agentos", category: "OpenAIProvider")

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

        let endpoint = provider.chatCompletionURL
        logger.debug("Sending request to \(endpoint.absoluteString) provider=\(self.provider.displayName) model=\(modelIdentifier)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            logger.error("Request timed out: \(endpoint.absoluteString)")
            throw AIProviderError.timeout
        } catch {
            logger.error("Network error: \(error.localizedDescription) url=\(endpoint.absoluteString)")
            throw AIProviderError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        logger.debug("Response status=\(http.statusCode) from \(self.provider.displayName)")

        switch http.statusCode {
        case 200:
            return try parseOpenAIResponse(data: data, modelIdentifier: modelIdentifier)
        case 401:
            logger.warning("Authentication failed for \(self.provider.displayName)")
            throw AIProviderError.missingAPIKey(provider)
        case 429:
            logger.warning("Rate limited by \(self.provider.displayName)")
            throw AIProviderError.rateLimited
        default:
            logger.error("Server error \(http.statusCode) from \(self.provider.displayName)")
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

// MARK: - CustomProviderAdapter

/// Adapts a `CustomProvider` (SwiftData model) to `AIProviderProtocol`.
/// Captures only the primitive values needed for the request — avoids holding the non-Sendable @Model.
struct CustomProviderAdapter: AIProviderProtocol {
    let baseURL: String
    let requiresAPIKey: Bool
    let keychainAccount: String
    let apiFormat: CustomProvider.APIFormat

    init(customProvider: CustomProvider) {
        self.baseURL = customProvider.baseURL
        self.requiresAPIKey = customProvider.requiresAPIKey
        self.keychainAccount = customProvider.keychainAccount
        self.apiFormat = customProvider.apiFormat
    }

    func complete(
        systemPrompt: String,
        userMessage: String,
        modelIdentifier: String,
        temperature: Double
    ) async throws -> AIResponse {
        switch apiFormat {
        case .anthropicMessages:
            return try await completeAnthropic(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                modelIdentifier: modelIdentifier,
                temperature: temperature
            )
        case .chatCompletions:
            return try await completeChatCompletions(
                systemPrompt: systemPrompt,
                userMessage: userMessage,
                modelIdentifier: modelIdentifier,
                temperature: temperature
            )
        }
    }

    private func completeChatCompletions(
        systemPrompt: String,
        userMessage: String,
        modelIdentifier: String,
        temperature: Double
    ) async throws -> AIResponse {
        let base = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/chat/completions") else {
            throw AIProviderError.invalidResponse
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAPIKey,
           let key = KeychainHelper.read(account: keychainAccount) {
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

        let (data, response) = try await performRequest(request)
        let http = try validateHTTPResponse(response)
        try checkStatusCode(http.statusCode)

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

        // Custom providers default to $0 cost — correct for local models (Ollama, LM Studio).
        // If the custom provider points to a paid API, the user should use a built-in provider instead.
        return AIResponse(content: text, inputTokens: inputTokens, outputTokens: outputTokens, costUSD: 0)
    }

    private func completeAnthropic(
        systemPrompt: String,
        userMessage: String,
        modelIdentifier: String,
        temperature: Double
    ) async throws -> AIResponse {
        let base = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/messages") else {
            throw AIProviderError.invalidResponse
        }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        if requiresAPIKey,
           let key = KeychainHelper.read(account: keychainAccount) {
            request.setValue(key, forHTTPHeaderField: "x-api-key")
        }

        let body: [String: Any] = [
            "model": modelIdentifier,
            "max_tokens": 4096,
            "temperature": temperature,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userMessage]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await performRequest(request)
        let http = try validateHTTPResponse(response)
        try checkStatusCode(http.statusCode)

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

        // Custom providers default to $0 cost — correct for local models (Ollama, LM Studio).
        return AIResponse(content: text, inputTokens: inputTokens, outputTokens: outputTokens, costUSD: 0)
    }

    // MARK: - Network Helpers

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .timedOut {
            throw AIProviderError.timeout
        } catch {
            throw AIProviderError.networkError(error)
        }
    }

    private func validateHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }
        return http
    }

    private func checkStatusCode(_ code: Int) throws {
        switch code {
        case 200: return
        case 429: throw AIProviderError.rateLimited
        default:  throw AIProviderError.serverError(code)
        }
    }
}

// MARK: - AIProviderFactory

enum AIProviderFactory {
    static func make(for provider: AIProvider) -> any AIProviderProtocol {
        provider == .anthropic
            ? ClaudeProvider()
            : OpenAICompatibleProvider(provider: provider)
    }

    static func make(for customProvider: CustomProvider) -> any AIProviderProtocol {
        CustomProviderAdapter(customProvider: customProvider)
    }
}
