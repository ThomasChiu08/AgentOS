import SwiftUI

struct ArtifactDetailView: View {
    let artifact: Artifact
    @State private var showExportConfirmation = false
    @State private var exportedPath: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            ScrollView {
                Text(artifact.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .navigationTitle(artifact.title)
        .navigationSubtitle(artifact.type.rawValue)
        .alert("Exported", isPresented: $showExportConfirmation) {
            Button("OK") {}
        } message: {
            Text("Saved to: \(exportedPath)")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Label(artifact.type.rawValue, systemImage: artifact.type.icon)
                .foregroundStyle(.secondary)
                .font(.subheadline)

            if let role = artifact.stage?.agentRole {
                Text("by \(role.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button("Copy", systemImage: "doc.on.doc") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(artifact.content, forType: .string)
            }
            .controlSize(.small)

            Button("Export", systemImage: "square.and.arrow.up") {
                exportArtifact()
            }
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Export

    private func exportArtifact() {
        let projectTitle = artifact.stage?.pipeline?.project?.title ?? "export"
        guard let role = artifact.stage?.agentRole else { return }

        do {
            let url = try FileExportService.export(
                content: artifact.content,
                role: role,
                projectTitle: projectTitle
            )
            artifact.filePath = url.path
            exportedPath = url.path
            showExportConfirmation = true
        } catch {
            exportedPath = "Failed to export artifact. \(error.localizedDescription)"
            showExportConfirmation = true
        }
    }
}
