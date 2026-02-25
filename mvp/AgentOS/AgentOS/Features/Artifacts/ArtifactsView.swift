import SwiftUI
import SwiftData

struct ArtifactsView: View {
    @Query(sort: \Pipeline.createdAt, order: .reverse) var pipelines: [Pipeline]
    @Query(sort: \Artifact.createdAt, order: .reverse) var allArtifacts: [Artifact]
    @State private var showAllHistory = false
    @State private var selectedArtifact: Artifact?

    private var artifacts: [Artifact] {
        if showAllHistory {
            return allArtifacts
        }
        guard let pipeline = pipelines.first else { return [] }
        return pipeline.orderedStages
            .flatMap { $0.artifacts }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        if artifacts.isEmpty {
            ContentUnavailableView(
                showAllHistory ? "No Artifacts Yet" : "No Artifacts in Current Pipeline",
                systemImage: "doc.richtext",
                description: Text(
                    showAllHistory
                        ? "Artifacts will appear here after pipeline stages complete."
                        : "This pipeline has no artifacts yet. Toggle \"Show All\" to view history."
                )
            )
            .navigationTitle("Artifacts")
            .toolbar { historyToggle }
        } else {
            NavigationSplitView {
                List(artifacts, selection: $selectedArtifact) { artifact in
                    ArtifactRow(artifact: artifact)
                        .tag(artifact)
                }
                .navigationTitle("Artifacts")
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
                .toolbar { historyToggle }
            } detail: {
                if let artifact = selectedArtifact {
                    ArtifactDetailView(artifact: artifact)
                } else {
                    ContentUnavailableView(
                        "No Artifact Selected",
                        systemImage: "doc.richtext",
                        description: Text("Select an artifact from the list.")
                    )
                }
            }
        }
    }

    private var historyToggle: some ToolbarContent {
        ToolbarItem(placement: .automatic) {
            Toggle("Show All", isOn: $showAllHistory)
                .toggleStyle(.switch)
                .help("Show artifacts from all pipelines")
        }
    }
}

// MARK: - Artifact Row

private struct ArtifactRow: View {
    let artifact: Artifact

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: artifact.type.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(artifact.title)
                    .font(.callout)
                    .lineLimit(2)
                Text(artifact.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
