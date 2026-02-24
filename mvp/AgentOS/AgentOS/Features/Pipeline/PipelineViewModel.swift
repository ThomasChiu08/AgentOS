import Foundation
import Observation
import SwiftData

@Observable final class PipelineViewModel {
    let pipeline: Pipeline
    let orchestrator: AgentOrchestrator

    init(pipeline: Pipeline, orchestrator: AgentOrchestrator) {
        self.pipeline = pipeline
        self.orchestrator = orchestrator
    }

    var orderedStages: [Stage] {
        pipeline.orderedStages
    }

    var totalCost: Double {
        pipeline.totalCostUSD
    }

    var yoloMode: Bool {
        get { pipeline.yoloMode }
        set { pipeline.yoloMode = newValue }
    }

    var projectTitle: String {
        pipeline.project?.title ?? "Untitled Pipeline"
    }

    func approve(stage: Stage) {
        orchestrator.approveCurrent(stage: stage)
    }

    func reject(stage: Stage) {
        orchestrator.rejectCurrent(stage: stage)
    }
}
