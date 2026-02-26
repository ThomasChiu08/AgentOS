import SwiftUI

struct CEOChatView: View {
    @Binding var selectedProjectID: UUID?
    @Environment(AgentOrchestrator.self) var orchestrator
    @Environment(\.modelContext) var modelContext
    @AppStorage("yoloModeDefault") private var yoloModeDefault = false
    @State private var viewModel = CEOChatViewModel()
    @State private var isSyncingProjectID = false

    var body: some View {
        VStack(spacing: 0) {
            messageList
            stateBar
            Divider()
            inputBar
        }
        .navigationTitle("CEO Chat")
        .onAppear { viewModel.orchestrator = orchestrator }
        .onChange(of: selectedProjectID) { _, newID in
            guard !isSyncingProjectID else { return }
            isSyncingProjectID = true
            defer { isSyncingProjectID = false }
            if let newID {
                viewModel.loadProject(id: newID, modelContext: modelContext)
            } else {
                viewModel.reset()
            }
        }
        .onChange(of: viewModel.currentProject?.id) { _, newID in
            guard !isSyncingProjectID, let newID, newID != selectedProjectID else { return }
            isSyncingProjectID = true
            defer { isSyncingProjectID = false }
            selectedProjectID = newID
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty && viewModel.chatState == .idle {
                        ContentUnavailableView(
                            "Welcome to AgentOS",
                            systemImage: "bubble.left.and.text.bubble.right",
                            description: Text("Type a task below and your AI team will get to work.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 80)
                    }
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if viewModel.chatState == .waitingForCEO {
                        TypingIndicator()
                    }
                    if viewModel.chatState == .pipelineRunning {
                        PipelineRunningIndicator()
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) {
                if let last = viewModel.messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - State Bar (proposal actions, errors)

    @ViewBuilder
    private var stateBar: some View {
        switch viewModel.chatState {
        case .proposalReady:
            VStack(alignment: .leading, spacing: 0) {
                PipelinePreviewView(pipeline: viewModel.currentPipeline)
                Divider()
                HStack(spacing: 12) {
                    Button("Approve Pipeline") {
                        Task { await viewModel.approvePipeline() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Start Over") {
                        viewModel.reset()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }

        case .pipelineRunning:
            HStack(spacing: 8) {
                ProgressView().scaleEffect(0.7)
                Text("Pipeline is running — switch to Pipeline Board to see progress.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

        case .completed:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Pipeline completed. Check Artifacts for results.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("New Task") { viewModel.reset() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

        case .error(let msg):
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
                Spacer()
                Button("Retry") { viewModel.reset() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

        case .idle, .waitingForCEO:
            EmptyView()
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            TextField("Describe a task for your AI team…", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 4)
                .onSubmit {
                    Task { await viewModel.sendMessage(modelContext: modelContext, yoloModeDefault: yoloModeDefault) }
                }

            HStack(spacing: 8) {
                ModelQuickPicker()
                Spacer()
                Button {
                    Task { await viewModel.sendMessage(modelContext: modelContext, yoloModeDefault: yoloModeDefault) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 6)
        }
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var canSend: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
        && viewModel.chatState == .idle
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user { Spacer(minLength: 60) }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.role == .user ? "You" : "CEO Agent")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Group {
                    if message.role == .ceo {
                        CEOMessageContentView(content: message.content)
                    } else {
                        Text(message.content)
                            .textSelection(.enabled)
                    }
                }
                .padding(10)
                .background(message.role == .user ? Color.blue : Color(nsColor: .controlBackgroundColor))
                .foregroundStyle(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            if message.role == .ceo { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Pipeline Preview

private struct PipelinePreviewView: View {
    let pipeline: Pipeline?

    var body: some View {
        if let pipeline {
            VStack(alignment: .leading, spacing: 4) {
                Text("Proposed Pipeline")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ForEach(pipeline.orderedStages) { stage in
                    HStack(spacing: 8) {
                        Image(systemName: stage.agentRole.icon)
                            .frame(width: 18)
                            .foregroundStyle(.secondary)
                        Text(stage.agentRole.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .frame(width: 80, alignment: .leading)
                        Text(String(stage.inputContext.prefix(60)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
        }
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().scaleEffect(0.6)
            Text("CEO is planning…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }
}

// MARK: - Pipeline Running Indicator

private struct PipelineRunningIndicator: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().scaleEffect(0.6)
            Text("Agents working…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }
}
