# AgentOS MVP — Phase 2 Backend Design

**Status:** Ready for implementation
**Phase:** 2 — Services layer + SwiftData integration
**Last Updated:** 2026-02-24

> This document is the authoritative spec for all backend services in MVP Phase 2.
> Each section can be used directly as implementation guide for its corresponding file.

---

## Overview

Phase 2 implements the `Core/Services/` and `Core/Utilities/` layers that are currently empty.
All Phase 1 Views and Models are in place — this phase wires everything together.

### New Files to Create

```
Core/
├── Services/
│   ├── AIProviderService.swift     ← Protocol + ClaudeProvider HTTP implementation
│   ├── AgentOrchestrator.swift     ← Pipeline state machine
│   ├── WebFetchService.swift       ← URLSession URL fetcher
│   └── FileExportService.swift     ← ~/Documents/AgentOS/ exporter
└── Utilities/
    ├── KeychainHelper.swift         ← API key Keychain storage
    └── PipelineParser.swift         ← CEO JSON → SwiftData objects
```

---

## 1. KeychainHelper

**File:** `Core/Utilities/KeychainHelper.swift`
**Dependencies:** None
**Implement first** — required by AIProviderService.

### Specification

```swift
import Security
import Foundation

enum KeychainHelper {
    private static let service = "com.thomas.agentos"
    private static let apiKeyAccount = "anthropic.apikey"

    static var apiKey: String? {
        get { read(account: apiKeyAccount) }
        set {
            if let value = newValue {
                save(value, account: apiKeyAccount)
            } else {
                delete(account: apiKeyAccount)
            }
        }
    }

    // MARK: - Private helpers

    private static func save(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func read(account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func delete(account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

---

## 2. AIProviderService

**File:** `Core/Services/AIProviderService.swift`
**Dependencies:** KeychainHelper
**Implement second** — foundational for all AI calls.

### Protocol

```swift
protocol AIProviderProtocol: Sendable {
    func complete(
        systemPrompt: String,
        userMessage: String,
        model: AIModel,
        temperature: Double
    ) async throws -> AIResponse
}

struct AIResponse: Sendable {
    let content: String
    let inputTokens: Int
    let outputTokens: Int
    let costUSD: Double
}
```

### AIModel Enum

```swift
enum AIModel: String, Sendable {
    case opusFull   = "claude-opus-4-6"
    case sonnet     = "claude-sonnet-4-6"
    case haiku      = "claude-haiku-4-5-20251001"

    var inputPricePerMillion: Double {
        switch self {
        case .opusFull: return 15.00
        case .sonnet:   return 3.00
        case .haiku:    return 0.80
        }
    }

    var outputPricePerMillion: Double {
        switch self {
        case .opusFull: return 75.00
        case .sonnet:   return 15.00
        case .haiku:    return 4.00
        }
    }
}
```

### AIProviderError

```swift
enum AIProviderError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case rateLimited
    case serverError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:    return "API key not set. Go to Settings to add your Anthropic key."
        case .invalidResponse:  return "Unexpected response from AI provider."
        case .rateLimited:      return "Rate limit reached. Please wait and try again."
        case .serverError(let code): return "Server error (\(code)). Please try again."
        case .networkError(let err): return "Network error: \(err.localizedDescription)"
        }
    }
}
```

### ClaudeProvider Implementation

```swift
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

        let (data, response) = try await URLSession.shared.data(for: request)

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

    private func parseResponse(data: Data, model: AIModel) throws -> AIResponse {
        // Anthropic response shape:
        // { "content": [{"type":"text","text":"..."}],
        //   "usage": {"input_tokens":N, "output_tokens":N} }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArr = json["content"] as? [[String: Any]],
              let text = contentArr.first?["text"] as? String,
              let usage = json["usage"] as? [String: Any],
              let inputTokens = usage["input_tokens"] as? Int,
              let outputTokens = usage["output_tokens"] as? Int
        else {
            throw AIProviderError.invalidResponse
        }

        let cost = (Double(inputTokens) / 1_000_000.0) * model.inputPricePerMillion
                 + (Double(outputTokens) / 1_000_000.0) * model.outputPricePerMillion

        return AIResponse(
            content: text,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            costUSD: cost
        )
    }
}
```

---

## 3. WebFetchService

**File:** `Core/Services/WebFetchService.swift`
**Dependencies:** None
**Used by:** Researcher agent stage in AgentOrchestrator.

### Specification

```swift
import Foundation

struct WebFetchService {
    static let maxContentLength = 8_000   // chars — prevent context overflow
    static let timeout: TimeInterval = 15

    static func fetch(url: URL) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.setValue("AgentOS/1.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            return "(Could not decode page content)"
        }

        let stripped = stripHTML(html)
        return String(stripped.prefix(maxContentLength))
    }

    // MARK: - HTML stripping

    private static func stripHTML(_ html: String) -> String {
        // Remove <script> and <style> blocks entirely
        var text = html
            .replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>",
                                  with: " ", options: .regularExpression)
            .replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>",
                                  with: " ", options: .regularExpression)

        // Remove all remaining HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)

        // Collapse whitespace
        text = text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespaces)
    }
}
```

---

## 4. FileExportService

**File:** `Core/Services/FileExportService.swift`
**Dependencies:** None
**Used by:** AgentOrchestrator after each stage completes.

### Specification

```swift
import Foundation

struct FileExportService {
    static let baseDir = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appending(path: "AgentOS")

    /// Exports artifact content to ~/Documents/AgentOS/{projectTitle}/{role}-{ISO8601}.md
    /// Returns the URL of the saved file.
    @discardableResult
    static func export(_ artifact: Artifact, projectTitle: String) async throws -> URL {
        let safeTitle = sanitizeFilename(projectTitle)
        let projectDir = baseDir.appending(path: safeTitle)
        try FileManager.default.createDirectory(at: projectDir,
                                                withIntermediateDirectories: true)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let timestamp = formatter.string(from: artifact.createdAt)
            .replacingOccurrences(of: ":", with: "-")

        let role = artifact.stage?.agentRole.rawValue ?? "unknown"
        let filename = "\(role)-\(timestamp).md"
        let fileURL = projectDir.appending(path: filename)

        try artifact.content.write(to: fileURL, atomically: true, encoding: .utf8)

        // Update artifact with saved path
        artifact.filePath = fileURL.path
        return fileURL
    }

    private static func sanitizeFilename(_ name: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_ "))
        return name
            .components(separatedBy: allowed.inverted)
            .joined(separator: "-")
            .trimmingCharacters(in: .init(charactersIn: "-"))
    }
}
```

---

## 5. PipelineParser

**File:** `Core/Utilities/PipelineParser.swift`
**Dependencies:** None (pure data transform)
**Used by:** CEOChatViewModel after CEO API response.

### CEO Output Contract

The CEO agent's system prompt instructs it to output a JSON block in this format:

```json
{
  "pipeline": [
    { "role": "researcher", "task": "Research top AI tools", "researchURLs": ["https://..."] },
    { "role": "producer",   "task": "Write a comparison report" },
    { "role": "qaReviewer", "task": "Review the report for accuracy" }
  ]
}
```

Valid role values: `researcher`, `producer`, `qaReviewer`

### Specification

```swift
import Foundation
import SwiftData

struct PipelineParser {

    struct ParsedStage {
        let role: AgentRole
        let task: String
        let researchURLs: [URL]
    }

    struct ParseResult {
        let stages: [ParsedStage]
        let rawText: String
    }

    /// Extract JSON pipeline block from CEO response text.
    /// Returns nil if no valid JSON block found (CEO gave a conversational response).
    static func parse(_ text: String) -> ParseResult? {
        guard let jsonString = extractJSONBlock(from: text),
              let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pipelineArray = json["pipeline"] as? [[String: Any]]
        else { return nil }

        let stages = pipelineArray.compactMap { item -> ParsedStage? in
            guard let roleString = item["role"] as? String,
                  let role = AgentRole(rawValue: roleString),
                  let task = item["task"] as? String
            else { return nil }

            let urls = (item["researchURLs"] as? [String] ?? [])
                .compactMap { URL(string: $0) }

            return ParsedStage(role: role, task: task, researchURLs: urls)
        }

        guard !stages.isEmpty else { return nil }
        return ParseResult(stages: stages, rawText: text)
    }

    /// Build SwiftData Stage objects from parsed stages.
    static func buildStages(from result: ParseResult, pipeline: Pipeline) -> [Stage] {
        result.stages.enumerated().map { index, parsed in
            let stage = Stage(
                agentRole: parsed.role,
                position: index,
                inputContext: parsed.task
            )
            stage.pipeline = pipeline
            return stage
        }
    }

    // MARK: - Private

    private static func extractJSONBlock(from text: String) -> String? {
        // Match ```json ... ``` block
        let pattern = "```json\\s*([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text)
        else {
            // Fallback: try to find bare { } JSON object
            return extractBareJSON(from: text)
        }
        return String(text[range])
    }

    private static func extractBareJSON(from text: String) -> String? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}")
        else { return nil }
        return String(text[start...end])
    }
}
```

---

## 6. AgentOrchestrator

**File:** `Core/Services/AgentOrchestrator.swift`
**Dependencies:** AIProviderService, WebFetchService, FileExportService
**The core state machine.** Implement last.

### Design Decisions

- `@MainActor` to ensure all SwiftData mutations + SwiftUI updates on main thread
- `@Observable` so `CEOChatViewModel` and `PipelineBoardView` can observe state
- Continuation-based pause for non-yolo mode (suspend at stage boundary, resume on user approval)

### Specification

```swift
import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class AgentOrchestrator {

    // MARK: - State

    var isRunning: Bool = false
    var currentError: Error?

    // MARK: - Dependencies

    private let provider: AIProviderProtocol
    private let modelContext: ModelContext

    // Continuation for non-yolo pause at stage boundary
    private var stageContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Init

    init(provider: AIProviderProtocol = ClaudeProvider(), modelContext: ModelContext) {
        self.provider = provider
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Start running a pipeline from the first waiting stage.
    func run(pipeline: Pipeline) async {
        guard !isRunning else { return }
        isRunning = true
        currentError = nil

        do {
            for stage in pipeline.orderedStages where stage.status == .waiting {
                try await executeStage(stage, pipeline: pipeline)

                // In non-yolo mode, pause here and wait for user approval
                if !pipeline.yoloMode && stage.status == .completed {
                    try await waitForApproval()
                }
            }
            pipeline.project?.status = .completed
        } catch {
            currentError = error
            pipeline.project?.status = .failed
        }

        isRunning = false
    }

    /// Called by UI when user taps "Approve" on a completed stage.
    func approveCurrent(stage: Stage) {
        stage.approved = true
        stage.status = .approved
        stageContinuation?.resume()
        stageContinuation = nil
    }

    /// Called by UI when user taps "Reject" on a completed stage.
    func rejectCurrent(stage: Stage, pipeline: Pipeline, reason: String = "User rejected") {
        stage.status = .failed
        pipeline.project?.status = .failed
        stageContinuation?.resume(throwing: OrchestratorError.userRejected(reason))
        stageContinuation = nil
        isRunning = false
    }

    // MARK: - Private

    private func executeStage(_ stage: Stage, pipeline: Pipeline) async throws {
        stage.status = .running

        let config = agentConfig(for: stage.agentRole, pipeline: pipeline)
        var context = buildContext(stage: stage, pipeline: pipeline)

        // Researcher: fetch URLs if present
        if stage.agentRole == .researcher {
            let urls = extractURLs(from: stage.inputContext)
            for url in urls.prefix(3) {  // max 3 URLs per stage
                if let fetched = try? await WebFetchService.fetch(url: url) {
                    context += "\n\n## Fetched: \(url.absoluteString)\n\(fetched)"
                }
            }
        }

        let response = try await provider.complete(
            systemPrompt: config.systemPrompt,
            userMessage: context,
            model: AIModel(rawValue: config.model) ?? .sonnet,
            temperature: config.temperature
        )

        stage.outputContent = response.content
        stage.costUSD = response.costUSD

        // Create artifact
        let artifact = Artifact(
            type: artifactType(for: stage.agentRole),
            title: "\(stage.agentRole.displayName) — \(pipeline.project?.title ?? "Untitled")",
            content: response.content
        )
        artifact.stage = stage
        modelContext.insert(artifact)
        stage.artifacts.append(artifact)

        // Export to disk
        try? await FileExportService.export(artifact, projectTitle: pipeline.project?.title ?? "project")

        // In yolo mode: auto-approve. Otherwise: await user.
        if pipeline.yoloMode {
            stage.approved = true
            stage.status = .approved
        } else {
            stage.status = .completed  // signals UI to show Approve/Reject
        }
    }

    private func waitForApproval() async throws {
        try await withCheckedThrowingContinuation { continuation in
            stageContinuation = continuation
        }
    }

    // MARK: - Context Building

    private func buildContext(stage: Stage, pipeline: Pipeline) -> String {
        var parts: [String] = []

        if let goal = pipeline.project?.title {
            parts.append("# Task\n\(goal)")
        }

        let previousStages = pipeline.orderedStages
            .filter { $0.position < stage.position && !$0.outputContent.isEmpty }

        if !previousStages.isEmpty {
            parts.append("# Previous Work")
            for prev in previousStages {
                parts.append("## \(prev.agentRole.displayName)\n\(prev.outputContent)")
            }
        }

        parts.append("# Your Job\n\(stage.inputContext)")
        return parts.joined(separator: "\n\n")
    }

    // MARK: - Helpers

    private func agentConfig(for role: AgentRole, pipeline: Pipeline) -> AgentConfig {
        // Look up from team if available; otherwise use defaults
        if let team = pipeline.project?.team,
           let config = team.agents.first(where: { $0.role == role }) {
            return config
        }
        return AgentConfig.default(for: role)
    }

    private func artifactType(for role: AgentRole) -> ArtifactType {
        switch role {
        case .producer: return .text
        case .researcher: return .text
        case .qaReviewer: return .text
        default: return .text
        }
    }

    private func extractURLs(from text: String) -> [URL] {
        let pattern = "https?://[^\\s]+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        return matches.compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return URL(string: String(text[range]))
        }
    }
}

// MARK: - Pipeline extension for ordered stages

extension Pipeline {
    var orderedStages: [Stage] {
        stages.sorted { $0.position < $1.position }
    }
}

// MARK: - AgentConfig defaults

extension AgentConfig {
    static func `default`(for role: AgentRole) -> AgentConfig {
        let config = AgentConfig(role: role)
        switch role {
        case .ceo:
            config.displayName = "CEO"
            config.model = AIModel.opusFull.rawValue
            config.temperature = 0.7
            config.systemPrompt = """
            You are the CEO agent. Decompose the user's goal into a pipeline of specialist agents.
            Output a JSON block with the following structure:
            ```json
            {
              "pipeline": [
                { "role": "researcher", "task": "...", "researchURLs": [] },
                { "role": "producer", "task": "..." },
                { "role": "qaReviewer", "task": "..." }
              ]
            }
            ```
            Valid roles: researcher, producer, qaReviewer
            """
        case .researcher:
            config.displayName = "Researcher"
            config.model = AIModel.sonnet.rawValue
            config.temperature = 0.3
            config.systemPrompt = "You are a research specialist. Gather comprehensive, accurate information on the given topic. Cite sources when possible."
        case .producer:
            config.displayName = "Producer"
            config.model = AIModel.sonnet.rawValue
            config.temperature = 0.7
            config.systemPrompt = "You are a content producer. Create high-quality, well-structured content based on the research provided."
        case .qaReviewer:
            config.displayName = "QA Reviewer"
            config.model = AIModel.sonnet.rawValue
            config.temperature = 0.3
            config.systemPrompt = "You are a QA specialist. Review the content for accuracy, clarity, and completeness. Provide specific improvement suggestions."
        default:
            config.displayName = role.displayName
            config.model = AIModel.sonnet.rawValue
            config.temperature = 0.5
            config.systemPrompt = "You are a specialist agent. Complete the assigned task to the best of your ability."
        }
        return config
    }
}

// MARK: - Error

enum OrchestratorError: LocalizedError {
    case userRejected(String)

    var errorDescription: String? {
        switch self {
        case .userRejected(let reason): return "Pipeline stopped: \(reason)"
        }
    }
}
```

---

## Cost Calculation Reference

| Model | Input (per 1M tokens) | Output (per 1M tokens) |
|-------|-----------------------|------------------------|
| claude-opus-4-6 | $15.00 | $75.00 |
| claude-sonnet-4-6 | $3.00 | $15.00 |
| claude-haiku-4-5-20251001 | $0.80 | $4.00 |

Cost formula: `(inputTokens / 1_000_000) × inputPrice + (outputTokens / 1_000_000) × outputPrice`

---

## Error Handling Strategy

| Error Type | User-Facing Message | Recovery |
|------------|--------------------|---------|
| Missing API key | "API key not set. Go to Settings." | Open SettingsView |
| Rate limited (429) | "Rate limit reached. Please wait." | Retry button |
| Server error (5xx) | "Server error. Please try again." | Retry button |
| Network error | "Network error: {description}" | Check connection |
| Parse failure | CEO chat shows raw text, no pipeline created | User re-prompts CEO |
| User rejected | Pipeline marked failed, shown in board | User starts new pipeline |

---

## Testing Checklist

Before marking Phase 2 backend complete:

- [ ] `KeychainHelper`: save → read → delete cycle works
- [ ] `ClaudeProvider`: successful call returns `AIResponse` with non-zero tokens
- [ ] `ClaudeProvider`: missing key throws `AIProviderError.missingAPIKey`
- [ ] `WebFetchService`: fetches real URL, strips HTML, truncates to 8000 chars
- [ ] `FileExportService`: creates `~/Documents/AgentOS/` directory and file
- [ ] `PipelineParser`: parses CEO JSON output into correct `ParsedStage[]`
- [ ] `PipelineParser`: returns nil for conversational CEO response
- [ ] `AgentOrchestrator`: runs 3-stage pipeline in yolo mode, all stages `.approved`
- [ ] `AgentOrchestrator`: pauses at each stage in non-yolo mode, resumes on approval

---

*See also: `docs/plans/mvp-phase2-frontend-design.md` for View integration details.*
