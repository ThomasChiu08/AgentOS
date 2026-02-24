import SwiftUI

// MARK: - Sidebar Navigation Items

enum SidebarItem: String, CaseIterable, Hashable {
    case chat = "CEO Chat"
    case pipeline = "Pipeline Board"
    case artifacts = "Artifacts"
    case team = "Team"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .chat:     return "bubble.left.and.bubble.right"
        case .pipeline: return "arrow.triangle.branch"
        case .artifacts: return "doc.richtext"
        case .team:     return "person.2"
        case .settings: return "gear"
        }
    }
}

// MARK: - Root View

struct ContentView: View {
    @State private var selection: SidebarItem? = .chat

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, id: \.self, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
            }
            .navigationTitle("AgentOS")
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Group {
                switch selection {
                case .chat:
                    CEOChatView()
                case .pipeline:
                    PipelineBoardView()
                case .artifacts:
                    ArtifactsView()
                case .team:
                    TeamView()
                case .settings:
                    SettingsView()
                case nil:
                    ContentUnavailableView(
                        "Select a Section",
                        systemImage: "sidebar.left",
                        description: Text("Choose an option from the sidebar.")
                    )
                }
            }
            .frame(minWidth: 500)
        }
    }
}
