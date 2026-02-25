import Foundation

/// Lightweight helper to verify Ollama connectivity and discover available models.
enum OllamaHealthCheck {
    struct ModelInfo: Sendable {
        let name: String
        let size: Int64
    }

    /// Pings `GET /api/tags` on the Ollama server and returns available model names.
    static func check(baseURL: String = "http://localhost:11434") async -> Result<[ModelInfo], Error> {
        let trimmed = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: trimmed + "/api/tags") else {
            return .failure(URLError(.badURL))
        }

        var request = URLRequest(url: url, timeoutInterval: 5)
        request.httpMethod = "GET"

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .failure(URLError(.badServerResponse))
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let models = json["models"] as? [[String: Any]]
            else {
                return .success([])
            }

            let infos = models.compactMap { dict -> ModelInfo? in
                guard let name = dict["name"] as? String else { return nil }
                let size = dict["size"] as? Int64 ?? 0
                return ModelInfo(name: name, size: size)
            }

            return .success(infos)
        } catch {
            return .failure(error)
        }
    }

    /// Returns just the model names for quick use in pickers.
    static func availableModelNames(baseURL: String = "http://localhost:11434") async -> [String] {
        switch await check(baseURL: baseURL) {
        case .success(let models):
            return models.map(\.name)
        case .failure:
            return []
        }
    }
}
