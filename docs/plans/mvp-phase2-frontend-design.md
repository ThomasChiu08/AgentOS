# AgentOS MVP — Phase 2 Frontend Design

**Status:** Ready for implementation
**Phase:** 2 — SwiftData integration + real API connection
**Last Updated:** 2026-02-24

> This document defines every View change needed in Phase 2.
> Assumes backend services (AIProviderService, AgentOrchestrator, etc.) are implemented first.

---

## Overview

Phase 1 Views use mock data (static structs). Phase 2 replaces all mocks with:
- `@Query` for reading live SwiftData
- `AgentOrchestrator` for driving pipeline execution
- Real API calls via `AIProviderService`

### Views Being Modified

| View | Change Type |
|------|------------|
| `CEOChatView` + `CEOChatViewModel` | Connect to real API + Orchestrator |
| `PipelineBoardView` + `PipelineViewModel` | `@Query` real Stages, Approve/Reject |
| `ArtifactsView` + `ArtifactDetailView` | `@Query` real Artifacts, copy/export |
| `TeamView` + `AgentCardView` | `@Query` real AgentConfigs + edit sheet |

### Views Being Created

| View | Purpose |
|------|---------|
| `Features/Settings/SettingsView.swift` | API key input, Yolo default, stats |
| `Features/Team/AgentConfigEditorView.swift` | Edit individual AgentConfig |

---

## A. Navigation Architecture (Existing — Document Only)

`ContentView.swift` uses `NavigationSplitView` with a sidebar.

```swift
enum SidebarItem: String, CaseIterable, Identifiable {
    case chat, pipeline, artifacts, team, settings

    var id: String { rawValue }
    var label: String { ... }
    var icon: String { ... }  // SF Symbol name
}
```

**Routing:** `@State private var selection: SidebarItem? = .chat`

**Phase 2 addition:** Add `.settings` case to `SidebarItem` and route to new `SettingsView`.

---

## B. CEO Chat — Phase 2 Specification

### State Machine

```
Idle → Sending → WaitingForCEO → ProposalReady → PipelineRunning → Completed
                                               ↘ Error
```

### CEOChatViewModel — Changes

**New properties:**

```swift
@Observable final class CEOChatViewModel {
    // Existing
    var messages: [ChatMessage] = []
    var inputText: String = ""

    // Phase 2 additions
    var chatState: ChatState = .idle
    var currentProject: Project?
    var currentPipeline: Pipeline?
    var errorMessage: String?

    // Dependencies (injected or via environment)
    var orchestrator: AgentOrchestrator?

    enum ChatState {
        case idle
        case sending
        case waitingForCEO
        case proposalReady(Pipeline)
        case pipelineRunning
        case completed
        case error(String)
    }
}
```

**`sendMessage()` — Phase 2 real flow:**

```swift
func sendMessage(modelContext: ModelContext) async {
    let trimmed = inputText.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else { return }

    // 1. Append user message
    messages.append(ChatMessage(role: .user, content: trimmed, timestamp: Date()))
    inputText = ""
    chatState = .waitingForCEO

    // 2. Create Project in SwiftData
    let project = Project(title: trimmed)
    modelContext.insert(project)

    // 3. Call CEO agent
    guard let orchestrator else { return }
    do {
        let ceoConfig = AgentConfig.default(for: .ceo)
        let response = try await orchestrator.provider.complete(
            systemPrompt: ceoConfig.systemPrompt,
            userMessage: trimmed,
            model: AIModel(rawValue: ceoConfig.model) ?? .opusFull,
            temperature: ceoConfig.temperature
        )

        // 4. Append CEO response message
        messages.append(ChatMessage(role: .ceo, content: response.content, timestamp: Date()))

        // 5. Try to parse pipeline
        if let parseResult = PipelineParser.parse(response.content) {
            let pipeline = Pipeline()
            pipeline.project = project
            project.pipeline = pipeline
            modelContext.insert(pipeline)

            let stages = PipelineParser.buildStages(from: parseResult, pipeline: pipeline)
            stages.forEach { modelContext.insert($0) }

            currentProject = project
            currentPipeline = pipeline
            chatState = .proposalReady(pipeline)
        } else {
            // Conversational response — no pipeline yet
            chatState = .idle
        }
    } catch {
        chatState = .error(error.localizedDescription)
        errorMessage = error.localizedDescription
    }
}

func approvePipeline() async {
    guard let pipeline = currentPipeline,
          let orchestrator else { return }
    chatState = .pipelineRunning
    await orchestrator.run(pipeline: pipeline)
    chatState = .completed
}
```

### CEOChatView — UI Changes

**Loading indicator (when state = .waitingForCEO):**
```swift
if chatState == .waitingForCEO {
    HStack {
        ProgressView().scaleEffect(0.7)
        Text("CEO is planning…").foregroundStyle(.secondary)
    }
}
```

**Pipeline proposal actions (when state = .proposalReady):**
```swift
if case .proposalReady = chatState {
    HStack {
        Button("Approve Pipeline") {
            Task { await viewModel.approvePipeline() }
        }
        .buttonStyle(.borderedProminent)

        Button("Start Over") {
            viewModel.chatState = .idle
            viewModel.currentPipeline = nil
        }
        .buttonStyle(.bordered)
    }
    .padding()
}
```

---

## C. Pipeline Board — Phase 2 Specification

### PipelineViewModel — Changes

**Remove mock data. Add real pipeline reference:**

```swift
@Observable final class PipelineViewModel {
    let pipeline: Pipeline
    let orchestrator: AgentOrchestrator

    init(pipeline: Pipeline, orchestrator: AgentOrchestrator) {
        self.pipeline = pipeline
        self.orchestrator = orchestrator
    }

    var orderedStages: [Stage] {
        pipeline.stages.sorted { $0.position < $1.position }
    }

    func approve(stage: Stage) {
        orchestrator.approveCurrent(stage: stage)
    }

    func reject(stage: Stage) {
        orchestrator.rejectCurrent(stage: stage, pipeline: pipeline)
    }
}
```

### PipelineBoardView — Changes

**Replace mock with @Query (or receive pipeline from parent):**

```swift
struct PipelineBoardView: View {
    // Option A: receive from parent (preferred — pipeline selected in sidebar)
    let pipeline: Pipeline
    @State private var viewModel: PipelineViewModel

    // Option B: @Query latest pipeline
    // @Query(sort: \Pipeline.project?.createdAt) var pipelines: [Pipeline]
}
```

**Approve/Reject buttons on StageCardView:**

```swift
// In StageCardView, when stage.status == .completed
if stage.status == .completed {
    HStack {
        Button("Approve") {
            onApprove?(stage)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)

        Button("Reject") {
            onReject?(stage)
        }
        .buttonStyle(.bordered)
        .tint(.red)
    }
}
```

**Yolo toggle binding:**

```swift
Toggle("Yolo Mode", isOn: Binding(
    get: { pipeline.yoloMode },
    set: { pipeline.yoloMode = $0 }
))
```

**Real-time updates:** `Stage.status` changes on main actor automatically trigger SwiftUI
re-render via `@Observable` — no explicit `objectWillChange` needed.

---

## D. Artifacts — Phase 2 Specification

### ArtifactsView — Changes

**Replace mock array with @Query:**

```swift
struct ArtifactsView: View {
    @Query(sort: \Artifact.createdAt, order: .reverse) var artifacts: [Artifact]
    // Optional filter by project:
    // @Query(filter: #Predicate<Artifact> { $0.stage?.pipeline?.project?.id == projectId })
}
```

**List renders `artifacts` directly** — no mock data.

### ArtifactDetailView — Changes

**Copy to clipboard:**

```swift
Button("Copy") {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(artifact.content, forType: .string)
}
```

**Export to file:**

```swift
Button("Export") {
    Task {
        if let url = try? await FileExportService.export(
            artifact,
            projectTitle: artifact.stage?.pipeline?.project?.title ?? "export"
        ) {
            // Show saved confirmation
            exportedURL = url
            showExportConfirmation = true
        }
    }
}
```

---

## E. Team — Phase 2 Specification

### TeamView — Changes

**Replace mock with @Query:**

```swift
struct TeamView: View {
    @Query var configs: [AgentConfig]
    @Environment(\.modelContext) var modelContext
    @State private var editingConfig: AgentConfig?

    var body: some View {
        List(configs) { config in
            AgentCardView(config: config)
                .onTapGesture { editingConfig = config }
        }
        .onAppear { seedDefaultConfigsIfNeeded() }
        .sheet(item: $editingConfig) { config in
            AgentConfigEditorView(config: config)
        }
    }

    private func seedDefaultConfigsIfNeeded() {
        guard configs.isEmpty else { return }
        let defaults: [AgentRole] = [.ceo, .researcher, .producer, .qaReviewer]
        defaults.forEach { role in
            modelContext.insert(AgentConfig.default(for: role))
        }
    }
}
```

### AgentConfigEditorView (New)

**File:** `Features/Team/AgentConfigEditorView.swift`

```swift
struct AgentConfigEditorView: View {
    @Bindable var config: AgentConfig
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Display Name", text: $config.displayName)
                }

                Section("Model") {
                    Picker("Model", selection: $config.model) {
                        Text("Opus 4.6 (Powerful)").tag(AIModel.opusFull.rawValue)
                        Text("Sonnet 4.6 (Balanced)").tag(AIModel.sonnet.rawValue)
                        Text("Haiku 4.5 (Fast)").tag(AIModel.haiku.rawValue)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("Temperature")
                        Slider(value: $config.temperature, in: 0...1, step: 0.1)
                        Text(String(format: "%.1f", config.temperature))
                            .monospacedDigit()
                    }
                }

                Section("System Prompt") {
                    TextEditor(text: $config.systemPrompt)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle("Edit \(config.displayName)")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

---

## F. Settings View (New)

**File:** `Features/Settings/SettingsView.swift`

```swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var apiKeyInput: String = ""
    @State private var apiKeySaved: Bool = false
    @AppStorage("yoloModeDefault") private var yoloModeDefault: Bool = false

    @Query var projects: [Project]

    var totalCost: Double {
        projects.flatMap { $0.pipeline?.stages ?? [] }
            .reduce(0) { $0 + $1.costUSD }
    }

    var body: some View {
        Form {
            Section("Anthropic API Key") {
                SecureField("sk-ant-…", text: $apiKeyInput)
                    .onAppear {
                        apiKeyInput = KeychainHelper.apiKey.map { _ in "••••••••" } ?? ""
                    }

                Button("Save Key") {
                    KeychainHelper.apiKey = apiKeyInput
                    apiKeySaved = true
                }
                .disabled(apiKeyInput.isEmpty)

                if apiKeySaved {
                    Label("Key saved securely in Keychain", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            Section("Defaults") {
                Toggle("Yolo Mode by default", isOn: $yoloModeDefault)
                Text("Skips human approval gates for all stages.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Usage") {
                LabeledContent("Total Projects", value: "\(projects.count)")
                LabeledContent("Total Cost", value: String(format: "$%.4f", totalCost))
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
    }
}
```

---

## G. ContentView — Navigation Addition

Add `.settings` to `SidebarItem` and route to `SettingsView`:

```swift
// In SidebarItem enum
case settings

var label: String {
    switch self {
    // ... existing cases ...
    case .settings: return "Settings"
    }
}

var icon: String {
    switch self {
    // ... existing cases ...
    case .settings: return "gear"
    }
}

// In ContentView detail routing
case .settings:
    SettingsView()
```

---

## H. Orchestrator Injection Pattern

`AgentOrchestrator` is created once in `AgentOSApp.swift` and injected via SwiftUI environment:

```swift
// AgentOSApp.swift
@main
struct AgentOSApp: App {
    let container = try! ModelContainer(for: Project.self, Pipeline.self, Stage.self,
                                        Artifact.self, AgentConfig.self, Team.self)
    @State private var orchestrator: AgentOrchestrator

    init() {
        let ctx = container.mainContext
        _orchestrator = State(initialValue: AgentOrchestrator(modelContext: ctx))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(orchestrator)
        }
    }
}
```

**ViewModels receive it via environment:**

```swift
struct CEOChatView: View {
    @Environment(AgentOrchestrator.self) var orchestrator
    @State private var viewModel = CEOChatViewModel()

    var body: some View {
        // ...
        .onAppear { viewModel.orchestrator = orchestrator }
    }
}
```

---

## I. State Flow Diagram

```
User types goal → CEOChatView
    ↓
CEOChatViewModel.sendMessage()
    ↓
[Project created in SwiftData]
    ↓
CEO API call → response
    ↓
PipelineParser.parse(response)
    ↓ success          ↓ failure
Pipeline + Stages    Chat shows raw text
created in DB        (conversational mode)
    ↓
UI shows "Approve Pipeline" button
    ↓
User taps Approve
    ↓
AgentOrchestrator.run(pipeline:)
    ↓ (for each stage)
Stage.status = .running
    ↓
AI call → response
    ↓
Stage.status = .completed (or .approved in yolo)
Artifact created + saved to disk
    ↓ (non-yolo)
PipelineBoardView shows Approve/Reject buttons
    ↓
User taps Approve → next stage
    ↓ (all stages done)
Project.status = .completed
ArtifactsView shows all Artifacts
```

---

## Phase 2 UI Checklist

- [ ] `ContentView`: Add `.settings` sidebar item
- [ ] `CEOChatViewModel`: Implement real `sendMessage()` with Project creation + CEO call
- [ ] `CEOChatView`: Add loading indicator + Approve/Reject pipeline buttons
- [ ] `PipelineViewModel`: Remove mock, use real `Pipeline` + `AgentOrchestrator`
- [ ] `PipelineBoardView`: `@Query` stages or receive pipeline from parent
- [ ] `StageCardView`: Add Approve/Reject buttons for `.completed` status
- [ ] `ArtifactsView`: `@Query` real Artifacts sorted by createdAt desc
- [ ] `ArtifactDetailView`: Implement Copy (NSPasteboard) + Export (FileExportService)
- [ ] `TeamView`: `@Query` configs, seed defaults on first launch, edit sheet
- [ ] `AgentConfigEditorView`: New file, name/model/temperature/prompt editing
- [ ] `SettingsView`: New file, API key input + Yolo default + usage stats
- [ ] `AgentOSApp`: Create `AgentOrchestrator`, inject via `.environment()`

---

*See also: `docs/plans/mvp-phase2-backend-design.md` for service implementations.*
