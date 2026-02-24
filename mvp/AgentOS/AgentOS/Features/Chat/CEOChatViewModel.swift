import Foundation
import Observation
import SwiftData

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

    /// True when no API key is saved for the default Anthropic provider.
    var apiKeyMissing: Bool {
        !KeychainHelper.hasKey(for: .anthropic)
    }

    func sendMessage(modelContext: ModelContext) async {
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
                model: ceoConfig.model,
                temperature: ceoConfig.temperature
            )

            messages.append(ChatMessage(role: .ceo, content: response.content, timestamp: Date()))

            // Try to parse pipeline from CEO output
            if let parsed = PipelineParser.parse(response.content) {
                // Create Project only after successful parse — avoids orphan records
                let project = Project(title: trimmed, goal: trimmed)
                modelContext.insert(project)
                currentProject = project

                let pipeline = Pipeline()
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
                chatState = .error("CEO couldn't generate a pipeline — try rephrasing your task or be more specific.")
            }
        } catch {
            chatState = .error(error.localizedDescription)
            messages.append(ChatMessage(
                role: .ceo,
                content: "Error: \(error.localizedDescription)",
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

    // MARK: - Private

    private func resolvedCEOConfig(modelContext: ModelContext) -> AgentConfig {
        // #Predicate can't reference static enum cases; capture the rawValue first.
        let roleRaw = AgentRole.ceo.rawValue
        var descriptor = FetchDescriptor<AgentConfig>(
            predicate: #Predicate { $0.role.rawValue == roleRaw }
        )
        descriptor.fetchLimit = 1
        if let saved = try? modelContext.fetch(descriptor).first {
            return saved
        }
        return AgentConfig(role: .ceo)
    }
}
