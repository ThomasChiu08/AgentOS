import SwiftUI

struct CEOMessageContentView: View {
    let content: String

    // Computed once per struct instance — avoids re-parsing on every SwiftUI body call
    private let segments: [MessageSegment]

    init(content: String) {
        self.content = content
        self.segments = PipelineParser.splitIntoSegments(content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let text):
                    Text(text)
                        .textSelection(.enabled)

                case .pipeline(let parsed):
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Pipeline Plan", systemImage: "arrow.triangle.branch")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        ForEach(Array(parsed.stages.enumerated()), id: \.offset) { index, stage in
                            PipelineStageCardView(stage: stage, index: index)
                        }
                    }
                }
            }
        }
    }
}
