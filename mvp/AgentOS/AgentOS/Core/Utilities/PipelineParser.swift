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

// MARK: - PipelineParser

enum PipelineParser {

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

    /// Extracts the JSON block from CEO output (```json ... ``` or bare { ... }).
    private static func extractJSONBlock(from text: String) -> String? {
        // Try ```json ... ``` first
        let fencedPattern = "```(?:json)?\\s*([\\s\\S]*?)```"
        if let regex = try? NSRegularExpression(pattern: fencedPattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            return String(text[range])
        }

        // Fallback: brace-depth tracking to find outermost { } pair
        return extractOutermostBraces(from: text)
    }

    /// Finds the outermost `{ ... }` in text using brace-depth tracking.
    /// More robust than firstIndex/lastIndex, which fails on nested objects.
    private static func extractOutermostBraces(from text: String) -> String? {
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
                    return String(text[start...i])
                }
            default:
                break
            }
        }
        return nil
    }
}
