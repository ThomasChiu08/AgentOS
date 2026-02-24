import SwiftUI
import SwiftData

// MARK: - Project List Sidebar

struct ProjectListView: View {
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Binding var selectedProjectID: UUID?
    var onNewTask: () -> Void

    var body: some View {
        List(selection: $selectedProjectID) {
            Section {
                Button(action: onNewTask) {
                    Label("New Task", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }

            if projects.isEmpty {
                Section {
                    Text("No projects yet — start a task in chat.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Section("Recent") {
                    ForEach(projects) { project in
                        ProjectRow(project: project)
                            .tag(project.id)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 180, idealWidth: 220, maxWidth: 280)
    }
}

// MARK: - Project Row

private struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(project.title)
                .font(.callout)
                .lineLimit(2)
            HStack(spacing: 4) {
                Image(systemName: project.status.icon)
                    .font(.caption2)
                    .foregroundStyle(statusColor)
                Text(project.createdAt, style: .relative)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var statusColor: Color {
        switch project.status {
        case .idle:      return .secondary
        case .running:   return .blue
        case .paused:    return .orange
        case .completed: return .green
        case .failed:    return .red
        }
    }
}
