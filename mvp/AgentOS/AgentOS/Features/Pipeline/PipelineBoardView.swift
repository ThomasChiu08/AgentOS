import SwiftUI
import SwiftData

struct PipelineBoardView: View {
    @Environment(AgentOrchestrator.self) var orchestrator
    @Query(sort: \Pipeline.createdAt, order: .reverse) var pipelines: [Pipeline]

    var body: some View {
        if let pipeline = pipelines.first {
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
