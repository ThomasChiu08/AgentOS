import SwiftUI
import SwiftData

struct ArtifactsView: View {
    @Query(sort: \Artifact.createdAt, order: .reverse) var artifacts: [Artifact]
    @State private var selectedArtifact: Artifact?

    var body: some View {
        if artifacts.isEmpty {
            ContentUnavailableView(
                "No Artifacts Yet",
                systemImage: "doc.richtext",
                description: Text("Artifacts will appear here after pipeline stages complete.")
            )
            .navigationTitle("Artifacts")
        } else {
            NavigationSplitView {
                List(artifacts, selection: $selectedArtifact) { artifact in
                    ArtifactRow(artifact: artifact)
                        .tag(artifact)
                }
                .navigationTitle("Artifacts")
                .navigationSplitViewColumnWidth(min: 220, ideal: 260)
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
