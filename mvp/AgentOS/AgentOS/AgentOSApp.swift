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
            let fm = FileManager.default
            let storeURL = config.url
            print("[AgentOS] ModelContainer failed: \(error)")
            print("[AgentOS] Store URL from config: \(storeURL.path)")

            // Also search the sandbox container's Application Support directory
            if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let defaultStore = appSupport.appendingPathComponent("default.store")
                print("[AgentOS] App Support dir: \(appSupport.path)")
                for suffix in ["", "-shm", "-wal"] {
                    let target = URL(fileURLWithPath: defaultStore.path + suffix)
                    guard fm.fileExists(atPath: target.path) else { continue }
                    do {
                        try fm.removeItem(at: target)
                        print("[AgentOS] Deleted: \(target.path)")
                    } catch {
                        print("[AgentOS] Failed to delete \(target.path): \(error)")
                    }
                }
            }

            // Also clean config.url location (may differ from Application Support)
            for suffix in ["", "-shm", "-wal"] {
                let target = URL(fileURLWithPath: storeURL.path + suffix)
                guard fm.fileExists(atPath: target.path) else { continue }
                do {
                    try fm.removeItem(at: target)
                    print("[AgentOS] Deleted: \(target.path)")
                } catch {
                    print("[AgentOS] Failed to delete \(target.path): \(error)")
                }
            }

            // Retry with persistent store
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                // Ultimate fallback: in-memory store so the app always launches
                print("[AgentOS] Retry failed: \(error). Falling back to in-memory store.")
                let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: [memConfig])
                } catch {
                    fatalError("Could not create ModelContainer even in-memory: \(error)")
                }
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
