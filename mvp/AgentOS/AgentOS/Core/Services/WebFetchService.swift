import Foundation

struct WebFetchService {
    static let maxContentLength = 8_000
    static let timeout: TimeInterval = 15

    /// Fetches a URL and returns plain text (HTML stripped, truncated to 8000 chars).
    static func fetch(url: URL) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue("AgentOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)

        guard let html = String(data: data, encoding: .utf8) else {
            return "(Could not decode page content)"
        }

        let text = stripHTML(html)
        return String(text.prefix(maxContentLength))
    }

    // MARK: - Private

    private static func stripHTML(_ html: String) -> String {
        var text = html

        // Remove <script> and <style> blocks entirely
        text = text.replacingOccurrences(
            of: "<script[^>]*>[\\s\\S]*?</script>",
            with: " ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "<style[^>]*>[\\s\\S]*?</style>",
            with: " ",
            options: .regularExpression
        )

        // Remove all remaining HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)

        // Collapse whitespace
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespaces)
    }
}
