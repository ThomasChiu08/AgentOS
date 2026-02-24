import Foundation
import SwiftData
import Observation

// MARK: - AgentOrchestrator

@MainActor
@Observable
final class AgentOrchestrator {

    // MARK: - Public State

    var isRunning = false
    var currentError: Error?

    // MARK: - Dependencies

    let modelContext: ModelContext

    // MARK: - Private

    private var approvalContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Init

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Runs all waiting stages in the pipeline sequentially.
    /// In non-yolo mode, pauses after each stage for user approval.
    func run(pipeline: Pipeline) async {
        guard !isRunning else { return }
        isRunning = true
        currentError = nil
        pipeline.project?.status = .running

        do {
            for stage in pipeline.orderedStages where stage.status == .waiting {
                try await executeStage(stage, pipeline: pipeline)

                // Non-yolo: suspend until user approves
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
        approvalContinuation?.resume()
        approvalContinuation = nil
    }

    /// Called by UI when user taps "Reject" on a completed stage.
    func rejectCurrent(stage: Stage) {
        stage.status = .failed
        approvalContinuation?.resume(throwing: OrchestratorError.rejected)
        approvalContinuation = nil
    }

    // MARK: - Stage Execution

    private func executeStage(_ stage: Stage, pipeline: Pipeline) async throws {
        stage.status = .running

        var context = buildContext(stage: stage, pipeline: pipeline)

        // Researcher stages: fetch any embedded URLs
        if stage.agentRole == .researcher {
            let urls = extractURLs(from: stage.inputContext)
            for url in urls.prefix(3) {
                if let fetched = try? await WebFetchService.fetch(url: url) {
                    context += "\n\n## Web Content: \(url.absoluteString)\n\(fetched)"
                }
            }
        }

        // Resolve per-agent config from SwiftData (falls back to defaults)
        let config = resolvedConfig(for: stage.agentRole)
        let stageProvider = AIProviderFactory.make(for: config.provider)

        let response = try await stageProvider.complete(
            systemPrompt: config.systemPrompt,
            userMessage: context,
            modelIdentifier: config.modelIdentifier,
            temperature: config.temperature
        )

        stage.outputContent = response.content

        // Parse quality score and recommendation for QA stages
        if stage.agentRole == .qaReviewer {
            stage.qualityScore = QAOutputParser.extractScore(from: response.content)
            stage.recommendation = QAOutputParser.extractRecommendation(from: response.content)
        }
        stage.costUSD = response.costUSD

        // Create artifact
        let projectTitle = pipeline.project?.title ?? "Untitled"
        let artifact = Artifact(
            type: artifactType(for: stage.agentRole),
            title: "\(stage.agentRole.rawValue) — \(projectTitle)",
            content: response.content
        )
        artifact.stage = stage
        modelContext.insert(artifact)
        stage.artifacts.append(artifact)

        // Export to disk
        if let exportURL = try? FileExportService.export(
            content: response.content,
            role: stage.agentRole,
            projectTitle: projectTitle
        ) {
            artifact.filePath = exportURL.path
        }

        // Yolo: auto-approve. Non-yolo: mark completed for user review.
        if pipeline.yoloMode {
            stage.approved = true
            stage.status = .approved
        } else {
            stage.status = .completed
        }
    }

    // MARK: - Config Resolution

    /// Fetches the saved AgentConfig for a given role from SwiftData.
    /// Falls back to a default config if none is persisted.
    private func resolvedConfig(for role: AgentRole) -> AgentConfig {
        let all = (try? modelContext.fetch(FetchDescriptor<AgentConfig>())) ?? []
        return all.first(where: { $0.role == role }) ?? AgentConfig(role: role)
    }

    // MARK: - Approval Suspension

    private func waitForApproval() async throws {
        try await withCheckedThrowingContinuation { continuation in
            approvalContinuation = continuation
        }
    }

    // MARK: - Context Building

    private func buildContext(stage: Stage, pipeline: Pipeline) -> String {
        var parts: [String] = []

        // Project goal / title
        if let project = pipeline.project {
            let goal = project.goal.isEmpty ? project.title : project.goal
            parts.append("# Task\n\(goal)")
        }

        // Previous stage outputs
        let previous = pipeline.orderedStages.filter {
            $0.position < stage.position && !$0.outputContent.isEmpty
        }
        if !previous.isEmpty {
            parts.append("# Previous Work")
            for prev in previous {
                parts.append("## \(prev.agentRole.rawValue)\n\(prev.outputContent)")
            }
        }

        // Current stage assignment
        parts.append("# Your Assignment\n\(stage.inputContext)")

        return parts.joined(separator: "\n\n")
    }

    // MARK: - Helpers

    private func artifactType(for role: AgentRole) -> ArtifactType {
        switch role {
        case .researcher:  return .notes
        case .producer:    return .document
        case .qaReviewer:  return .report
        case .ceo:         return .document
        }
    }

    private func extractURLs(from text: String) -> [URL] {
        let pattern = "https?://[^\\s]+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .compactMap { match in
                guard let range = Range(match.range, in: text) else { return nil }
                return URL(string: String(text[range]))
            }
    }
}

// MARK: - OrchestratorError

enum OrchestratorError: LocalizedError {
    case rejected

    var errorDescription: String? {
        "Pipeline stopped by user."
    }
}
