import Foundation

enum QAOutputParser {
    static func extractScore(from text: String) -> Int? {
        let pattern = #"Quality Score:\s*(\d+)/10"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { return nil }
        return Int(text[range])
    }

    static func extractRecommendation(from text: String) -> String? {
        let pattern = #"Recommendation:\s*(APPROVE|REVISE|REJECT)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else { return nil }
        return String(text[range])
    }
}
