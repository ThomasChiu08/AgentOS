import Foundation
import Observation
import SwiftData
import os

// MARK: - ChatMessage

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date

    enum MessageRole {
        case user, ceo
    }
}

// MARK: - ChatState

enum ChatState: Equatable {
    case idle
    case waitingForCEO
    case proposalReady
    case pipelineRunning
    case completed
    case error(String)

    static func == (lhs: ChatState, rhs: ChatState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.waitingForCEO, .waitingForCEO),
             (.proposalReady, .proposalReady),
             (.pipelineRunning, .pipelineRunning),
             (.completed, .completed):
            return true
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - ViewModel

@Observable final class CEOChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var chatState: ChatState = .idle
    var currentProject: Project?
    var currentPipeline: Pipeline?

    // Injected from View via .onAppear
    var orchestrator: AgentOrchestrator?

    private let logger = Logger(subsystem: "com.thomas.agentos", category: "CEOChat")

    func sendMessage(modelContext: ModelContext, yoloModeDefault: Bool = false) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        // Block new messages while a proposal is awaiting approval
        guard chatState != .proposalReady else { return }

        // Pre-flight: validate API key before committing message to history
        let ceoConfig = resolvedCEOConfig(modelContext: modelContext)
        if ceoConfig.provider.requiresAPIKey {
            guard KeychainHelper.hasKey(for: ceoConfig.provider) else {
                chatState = .error("API key for \(ceoConfig.provider.displayName) not set. Go to Settings → API Keys.")
                return
            }
        }

        messages.append(ChatMessage(role: .user, content: trimmed, timestamp: Date()))
        inputText = ""
        chatState = .waitingForCEO

        guard let orchestrator else {
            chatState = .error("Orchestrator not available.")
            return
        }

        let ceoProvider = AIProviderFactory.make(for: ceoConfig.provider)

        do {
            let response = try await ceoProvider.complete(
                systemPrompt: ceoConfig.systemPrompt,   // use AgentConfig prompt, not hardcoded
                userMessage: trimmed,
                modelIdentifier: ceoConfig.modelIdentifier,
                temperature: ceoConfig.temperature
            )

            messages.append(ChatMessage(role: .ceo, content: response.content, timestamp: Date()))

            // Try to parse pipeline from CEO output
            if let parsed = PipelineParser.parse(response.content) {
                // Create Project only after successful parse — avoids orphan records
                let project = Project(title: trimmed, goal: trimmed)
                modelContext.insert(project)
                currentProject = project

                let pipeline = Pipeline(yoloMode: yoloModeDefault)
                pipeline.project = project
                project.pipeline = pipeline
                modelContext.insert(pipeline)

                let stages = PipelineParser.buildStages(from: parsed, pipeline: pipeline)
                for stage in stages {
                    modelContext.insert(stage)
                    pipeline.stages.append(stage)
                }

                currentPipeline = pipeline
                chatState = .proposalReady
            } else {
                logger.warning("CEO response failed to parse: \(response.content.prefix(500))")
                chatState = .error("CEO couldn't generate a pipeline — try rephrasing your task or be more specific.")
            }
        } catch {
            let userMessage = Self.friendlyErrorMessage(for: error)
            logger.error("CEO request failed: \(error)")
            chatState = .error(userMessage)
            messages.append(ChatMessage(
                role: .ceo,
                content: "Error: \(userMessage)",
                timestamp: Date()
            ))
        }
    }

    func approvePipeline() async {
        guard let pipeline = currentPipeline,
              let orchestrator
        else { return }

        chatState = .pipelineRunning
        await orchestrator.run(pipeline: pipeline)

        if orchestrator.currentError != nil {
            chatState = .error(orchestrator.currentError?.localizedDescription ?? "Pipeline failed")
        } else {
            chatState = .completed
        }
    }

    func reset() {
        chatState = .idle
        currentProject = nil
        currentPipeline = nil
        messages = []
    }

    /// Loads an existing project from history into the chat view.
    func loadProject(id: UUID, modelContext: ModelContext) {
        // Don't reload if already showing this project
        if currentProject?.id == id { return }

        let project: Project
        do {
            let all = try modelContext.fetch(FetchDescriptor<Project>())
            guard let found = all.first(where: { $0.id == id }) else {
                chatState = .error("Project not found.")
                return
            }
            project = found
        } catch {
            chatState = .error("Failed to load project: \(error.localizedDescription)")
            return
        }

        messages = []
        currentProject = project
        currentPipeline = project.pipeline

        messages.append(ChatMessage(
            role: .ceo,
            content: "Loaded project: \(project.title)",
            timestamp: project.createdAt
        ))

        switch project.status {
        case .completed:
            chatState = .completed
        case .failed:
            chatState = .error("Pipeline failed — check Pipeline Board for details.")
        case .running:
            chatState = .pipelineRunning
        case .idle:
            chatState = project.pipeline != nil ? .proposalReady : .idle
        case .paused:
            chatState = .proposalReady
        }
    }

    // MARK: - Private

    // MARK: - Helpers

    private func resolvedCEOConfig(modelContext: ModelContext) -> AgentConfig {
        let all = (try? modelContext.fetch(FetchDescriptor<AgentConfig>())) ?? []
        return all.first(where: { $0.role == .ceo }) ?? AgentConfig(role: .ceo)
    }

    /// Translates raw network/provider errors into actionable user-facing messages.
    static func friendlyErrorMessage(for error: Error) -> String {
        if let providerError = error as? AIProviderError {
            return providerError.localizedDescription ?? error.localizedDescription
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotConnectToHost, .cannotFindHost:
                let host = urlError.failingURL?.host() ?? "server"
                if host == "localhost" || host == "127.0.0.1" {
                    return "Cannot connect to local server. Make sure Ollama is running: `ollama serve`"
                }
                return "Cannot connect to \(host). Check your network connection."
            case .timedOut:
                return "Request timed out. The model may still be loading — try again in a moment."
            case .notConnectedToInternet:
                return "No internet connection. Check your network settings."
            case .secureConnectionFailed:
                return "Secure connection failed. Check your API endpoint URL."
            default:
                return "Network error: \(urlError.localizedDescription)"
            }
        }

        return error.localizedDescription
    }
}
