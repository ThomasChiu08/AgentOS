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

    // CEO system prompt with JSON output instruction
    private let ceoSystemPrompt = """
    You are the CEO of a virtual AI team. Your job is to understand the user's goal \
    and decompose it into a clear, sequential pipeline of tasks for specialist agents.

    Output your plan as a JSON block:
    ```json
    {
      "pipeline": [
        { "role": "researcher", "task": "...", "researchURLs": [] },
        { "role": "producer", "task": "..." },
        { "role": "qaReviewer", "task": "..." }
      ]
    }
    ```
    Valid roles: researcher, producer, qaReviewer.
    After the JSON block, include a brief conversational summary of what the pipeline will do.
    """

    func sendMessage(modelContext: ModelContext) async {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(role: .user, content: trimmed, timestamp: Date()))
        inputText = ""
        chatState = .waitingForCEO

        // Create project
        let project = Project(title: trimmed, goal: trimmed)
        modelContext.insert(project)
        currentProject = project

        guard let orchestrator else {
            chatState = .error("Orchestrator not available.")
            return
        }

        do {
            let response = try await orchestrator.provider.complete(
                systemPrompt: ceoSystemPrompt,
                userMessage: trimmed,
                model: .claudeOpus,
                temperature: 0.7
            )

            messages.append(ChatMessage(role: .ceo, content: response.content, timestamp: Date()))

            // Try to parse pipeline from CEO output
            if let parsed = PipelineParser.parse(response.content) {
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
                // Conversational response — no pipeline created
                chatState = .idle
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
    }
}
