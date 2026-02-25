import Foundation
import SwiftData

// MARK: - Parsed Intermediate Types

struct ParsedStage {
    let role: AgentRole
    let task: String
    let researchURLs: [URL]
}

struct ParsedPipeline {
    let stages: [ParsedStage]
}

// MARK: - Message Segment

enum MessageSegment {
    case text(String)
    case pipeline(ParsedPipeline)
}

// MARK: - PipelineParser

enum PipelineParser {

    // MARK: - Cached Regex (HIGH #2 fix: avoid recompiling on every call)

    private static let fencedBlockRegex = try? NSRegularExpression(
        pattern: "```(?:json)?\\s*[\\s\\S]*?```"
    )
    private static let fencedContentRegex = try? NSRegularExpression(
        pattern: "```(?:json)?\\s*([\\s\\S]*?)```"
    )

    /// Splits CEO message content into renderable segments (text + pipeline cards).
    static func splitIntoSegments(_ text: String) -> [MessageSegment] {
        guard let range = jsonBlockRange(from: text) else {
            return [.text(text)]
        }

        var segments: [MessageSegment] = []

        // Text before the JSON block
        let before = String(text[text.startIndex..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !before.isEmpty {
            segments.append(.text(before))
        }

        // Pipeline card (falls back to raw text if parse fails)
        if let parsed = parse(text) {
            segments.append(.pipeline(parsed))
        } else {
            segments.append(.text(String(text[range])))
        }

        // Text after the JSON block — strip numbered summary lines
        let after = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = stripNumberedSummary(after)
        if !cleaned.isEmpty {
            segments.append(.text(cleaned))
        }

        return segments
    }

    /// Extracts a pipeline plan from CEO text output.
    /// Returns nil if no valid JSON block found (conversational response).
    static func parse(_ text: String) -> ParsedPipeline? {
        guard
            let jsonString = extractJSONBlock(from: text),
            let data = jsonString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let pipelineArray = json["pipeline"] as? [[String: Any]]
        else { return nil }

        let stages = pipelineArray.compactMap { item -> ParsedStage? in
            guard
                let roleString = item["role"] as? String,
                let role = parseRole(roleString),
                let task = item["task"] as? String
            else { return nil }

            let urls = (item["researchURLs"] as? [String] ?? [])
                .compactMap { URL(string: $0) }

            return ParsedStage(role: role, task: task, researchURLs: urls)
        }

        guard !stages.isEmpty, stages.count <= 6 else { return nil }
        return ParsedPipeline(stages: stages)
    }

    /// Creates SwiftData Stage objects from a parsed pipeline.
    static func buildStages(from parsed: ParsedPipeline, pipeline: Pipeline) -> [Stage] {
        parsed.stages.enumerated().map { index, parsedStage in
            // Embed research URLs into the inputContext so the researcher stage can find them
            var context = parsedStage.task
            if !parsedStage.researchURLs.isEmpty {
                let urlList = parsedStage.researchURLs.map { $0.absoluteString }.joined(separator: "\n")
                context += "\n\nResearch URLs:\n\(urlList)"
            }

            let stage = Stage(agentRole: parsedStage.role, position: index, inputContext: context)
            stage.pipeline = pipeline
            return stage
        }
    }

    // MARK: - Private

    /// Maps CEO JSON role strings (lowercase camelCase) to AgentRole enum cases.
    private static func parseRole(_ string: String) -> AgentRole? {
        switch string.lowercased() {
        case "researcher":                          return .researcher
        case "producer", "writer",
             "content_producer":                    return .producer
        case "qareviewer", "qa_reviewer",
             "qa reviewer", "reviewer", "qa":       return .qaReviewer
        default:                                    return nil
        }
    }

    /// Returns the range of the entire fenced code block (including backticks) or outermost braces.
    private static func jsonBlockRange(from text: String) -> Range<String.Index>? {
        if let regex = fencedBlockRegex,
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range, in: text) {
            return range
        }
        return outermostBracesRange(from: text)
    }

    /// Extracts the JSON content from CEO output (```json ... ``` or bare { ... }).
    private static func extractJSONBlock(from text: String) -> String? {
        if let regex = fencedContentRegex,
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }
        return outermostBracesRange(from: text).map { String(text[$0]) }
    }

    /// Returns the Range of the outermost `{ ... }` pair using brace-depth tracking.
    /// Note: blind to braces inside string values — fenced-block regex path is preferred.
    private static func outermostBracesRange(from text: String) -> Range<String.Index>? {
        var depth = 0
        var startIndex: String.Index?
        for i in text.indices {
            switch text[i] {
            case "{":
                if depth == 0 { startIndex = i }
                depth += 1
            case "}":
                depth -= 1
                if depth == 0, let start = startIndex {
                    return start..<text.index(after: i)
                }
            default:
                break
            }
        }
        return nil
    }

    /// Strips leading numbered summary lines (e.g. "1. Researcher → ...").
    private static func stripNumberedSummary(_ text: String) -> String {
        let lines = text.components(separatedBy: .newlines)
        let filtered = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // Match "1. ", "2. ", etc.
            guard let first = trimmed.first, first.isNumber else { return true }
            let pattern = "^\\d+\\.\\s+"
            return trimmed.range(of: pattern, options: .regularExpression) == nil
        }
        return filtered.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
