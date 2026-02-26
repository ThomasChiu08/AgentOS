import SwiftUI
import SwiftData

struct PipelineBoardView: View {
    var selectedProjectID: UUID?

    @Environment(AgentOrchestrator.self) var orchestrator
    @Query(sort: \Pipeline.updatedAt, order: .reverse) var pipelines: [Pipeline]

    /// Resolves the pipeline to display: matches selectedProjectID if provided, else latest.
    private var activePipeline: Pipeline? {
        if let selectedProjectID {
            return pipelines.first(where: { $0.project?.id == selectedProjectID })
        }
        return pipelines.first
    }

    var body: some View {
        if let pipeline = activePipeline {
            PipelineContent(pipeline: pipeline, orchestrator: orchestrator)
        } else {
            ContentUnavailableView(
                "No Pipeline Yet",
                systemImage: "arrow.triangle.branch",
                description: Text("Start a task in CEO Chat to create a pipeline.")
            )
            .navigationTitle("Pipeline Board")
        }
    }
}

// MARK: - Pipeline Content (with real data)

private struct PipelineContent: View {
    let pipeline: Pipeline
    @State private var viewModel: PipelineViewModel

    init(pipeline: Pipeline, orchestrator: AgentOrchestrator) {
        self.pipeline = pipeline
        _viewModel = State(initialValue: PipelineViewModel(pipeline: pipeline, orchestrator: orchestrator))
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            if let error = viewModel.currentError {
                errorBanner(error)
            }
            Divider()
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.orderedStages) { stage in
                        StageCardView(
                            stage: stage,
                            onApprove: { viewModel.approve(stage: stage) },
                            onReject: { viewModel.reject(stage: stage) }
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Pipeline Board")
    }

    // MARK: - Error Banner

    private func errorBanner(_ error: Error) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundStyle(.red)
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color.red.opacity(0.08))
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack {
            Label(viewModel.projectTitle, systemImage: "doc.text")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Text(String(format: "Total: $%.4f", viewModel.totalCost))
                .font(.subheadline)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Toggle("Yolo Mode", isOn: Binding(
                get: { viewModel.yoloMode },
                set: { viewModel.yoloMode = $0 }
            ))
            .toggleStyle(.switch)
            .controlSize(.small)
            .help("Skip approval gates and run the pipeline fully automatically.")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
