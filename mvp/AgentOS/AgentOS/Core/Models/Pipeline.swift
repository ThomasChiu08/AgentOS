import Foundation
import SwiftData

@Model final class Pipeline {
    var id: UUID
    var yoloMode: Bool
    var createdAt: Date
    var updatedAt: Date

    var project: Project?
    @Relationship(deleteRule: .cascade) var stages: [Stage]

    /// Stages sorted by their position in the pipeline.
    var orderedStages: [Stage] {
        stages.sorted { $0.position < $1.position }
    }

    /// Sum of all stage costs in USD.
    var totalCostUSD: Double {
        stages.reduce(0) { $0 + $1.costUSD }
    }

    /// Marks the pipeline as modified so `@Query` observers detect the change.
    func touch() {
        updatedAt = Date()
    }

    init(yoloMode: Bool = false) {
        self.id = UUID()
        self.yoloMode = yoloMode
        self.createdAt = Date()
        self.updatedAt = Date()
        self.stages = []
    }
}
