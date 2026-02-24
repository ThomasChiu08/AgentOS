import Foundation

extension String {
    /// Strips common markdown syntax for plain-text display.
    var strippedMarkdown: String {
        var result = self
        // Remove headers
        result = result.replacingOccurrences(of: #"#{1,6}\s"#, with: "", options: .regularExpression)
        // Remove bold/italic
        result = result.replacingOccurrences(of: #"\*{1,3}([^*]+)\*{1,3}"#, with: "$1", options: .regularExpression)
        // Remove inline code
        result = result.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Truncates to a given character limit, appending ellipsis if needed.
    func truncated(to limit: Int) -> String {
        guard count > limit else { return self }
        return String(prefix(limit)) + "…"
    }
}
