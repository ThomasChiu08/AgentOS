import SwiftUI
import SwiftData

@main
struct AgentOSApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
            Pipeline.self,
            Stage.self,
            Artifact.self,
            AgentConfig.self,
            CustomProvider.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
#if DEBUG
            // Schema changed — delete the incompatible store and recreate (dev-time only).
            let storeURL = config.url
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
#else
            fatalError("ModelContainer failed — a MigrationPlan is required: \(error)")
#endif
        }
    }()

    @State private var orchestrator: AgentOrchestrator?

    var body: some Scene {
        WindowGroup {
            if let orchestrator {
                ContentView()
                    .modelContainer(sharedModelContainer)
                    .environment(orchestrator)
            } else {
                ProgressView("Starting AgentOS…")
                    .frame(width: 300, height: 200)
                    .task {
                        orchestrator = AgentOrchestrator(
                            modelContext: sharedModelContainer.mainContext
                        )
                    }
            }
        }
    }
}
