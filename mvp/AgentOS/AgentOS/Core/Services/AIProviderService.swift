import Foundation

// MARK: - AIModel Pricing Extension

extension AIModel {
    var inputPricePerMillion: Double {
        switch self {
        case .claudeOpus:   return 15.00
        case .claudeSonnet: return 3.00
        case .claudeHaiku:  return 0.80
        }
    }

    var outputPricePerMillion: Double {
        switch self {
        case .claudeOpus:   return 75.00
        case .claudeSonnet: return 15.00
        case .claudeHaiku:  return 4.00
        }
    }
}

// MARK: - Protocol

protocol AIProviderProtocol: Sendable {
    func complete(
        systemPrompt: String,
        userMessage: String,
        model: AIModel,
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
    case missingAPIKey
    case invalidResponse
    case rateLimited
    case serverError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key not set. Open Settings to add your Anthropic key."
        case .invalidResponse:
            return "Unexpected response from AI provider."
        case .rateLimited:
            return "Rate limit reached. Please wait and try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

// MARK: - ClaudeProvider

struct ClaudeProvider: AIProviderProtocol {
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let anthropicVersion = "2023-06-01"

    func complete(
        systemPrompt: String,
        userMessage: String,
        model: AIModel,
        temperature: Double
    ) async throws -> AIResponse {
        guard let apiKey = KeychainHelper.apiKey, !apiKey.isEmpty else {
            throw AIProviderError.missingAPIKey
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model.rawValue,
            "max_tokens": 4096,
            "temperature": temperature,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userMessage]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AIProviderError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse
        }

        switch http.statusCode {
        case 200:
            return try parseResponse(data: data, model: model)
        case 401:
            throw AIProviderError.missingAPIKey
        case 429:
            throw AIProviderError.rateLimited
        default:
            throw AIProviderError.serverError(http.statusCode)
        }
    }

    // MARK: - Private

    private func parseResponse(data: Data, model: AIModel) throws -> AIResponse {
        // Anthropic response shape:
        // { "content": [{"type":"text","text":"..."}],
        //   "usage": {"input_tokens": N, "output_tokens": N} }
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

        let cost = (Double(inputTokens) / 1_000_000) * model.inputPricePerMillion
                 + (Double(outputTokens) / 1_000_000) * model.outputPricePerMillion

        return AIResponse(
            content: text,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            costUSD: cost
        )
    }
}
