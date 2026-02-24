# AgentOS — Technical Architecture

**Last Updated:** 2026-02-24  
**Status:** Draft v1

---

## Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| UI | SwiftUI | Declarative, native macOS, no additional deps |
| Storage | SwiftData | Type-safe, integrates with SwiftUI, no Core Data boilerplate |
| Networking | URLSession | Built-in, async/await support, no Alamofire needed |
| AI | Anthropic API (direct HTTP) | Full control, no SDK lock-in for MVP |
| Concurrency | Swift async/await + actors | Native, safe, composable |
| Architecture | MVVM | Standard for SwiftUI, clear separation |

---

## Key Architecture Decisions

### Decision 1: No Python Backend

**Rejected:** Python FastAPI backend + Swift frontend  
**Chosen:** Pure Swift client-only app

**Reasoning:**
- AgentOS is fundamentally a UI orchestration layer for API calls
- Swift async/await handles concurrent API calls without extra infrastructure
- Eliminates deployment complexity (no server to maintain)
- Reduces attack surface (API keys stay on device in Keychain)
- Client-only apps ship faster for solo developers

### Decision 2: No OpenAPI Spec

**Rejected:** Generate Swift client from OpenAPI spec  
**Chosen:** Swift Protocol-based abstraction

**Reasoning:**
- No server to spec — this is a pure client app
- Swift protocols are more flexible and idiomatic than generated code
- `AIProviderProtocol` cleanly abstracts Claude / GPT / Gemini differences
- Adding a new provider = implementing one protocol, not regenerating code

### Decision 3: SwiftData over Core Data

**Rejected:** Core Data  
**Chosen:** SwiftData

**Reasoning:**
- SwiftData is the modern, Swift-native persistence layer (macOS 14+)
- `@Model` macro removes boilerplate
- First-class SwiftUI integration via `@Query`
- App targets macOS 14+ anyway — SwiftData is available

---

## Module Structure

```
AgentOS/
├── App/                    # Entry point, app lifecycle, root navigation
├── Features/               # Feature modules (high cohesion, vertical slices)
│   ├── Chat/               # CEO Chat view + ViewModel
│   ├── Pipeline/           # Pipeline Board, Stage cards
│   ├── Artifacts/          # Artifacts browser and detail
│   └── Team/               # Agent configuration
├── Core/
│   ├── Models/             # SwiftData @Model classes
│   ├── Services/           # Business logic, orchestration, AI calls
│   └── Extensions/         # Swift/SwiftUI extensions
└── Resources/              # Assets, Localizable strings
```

**Principle:** Features own their Views and ViewModels. Core owns shared Models and Services. Features call Services; Services never import Features.

---

## Data Models

### SwiftData Entities

```swift
// Project — top-level goal the user wants to accomplish
@Model
class Project {
    var id: UUID
    var title: String
    var createdAt: Date
    var status: ProjectStatus     // pending | running | completed | failed
    @Relationship var pipeline: Pipeline?
    @Relationship var team: Team?
}

// Pipeline — the execution plan for a Project
@Model
class Pipeline {
    var id: UUID
    @Relationship(inverse: \Project.pipeline) var project: Project?
    @Relationship var stages: [Stage]
    // edges stored as JSON for MVP; graph structure for V1
    var edgesJSON: String         // [(stageId, stageId)] serialized
}

// Stage — one agent's unit of work
@Model
class Stage {
    var id: UUID
    @Relationship(inverse: \Pipeline.stages) var pipeline: Pipeline?
    var agentRole: AgentRole      // enum: ceo | researcher | producer | reviewer | editor | ops | finance
    var status: StageStatus       // pending | running | awaitingApproval | approved | failed | done
    var inputContext: String       // what this stage received
    var outputContent: String?     // what this stage produced
    var costUSD: Double            // tokens × price
    var approved: Bool
    var sortOrder: Int
    @Relationship var artifact: Artifact?
}

// Artifact — the persistent output of a Stage
@Model
class Artifact {
    var id: UUID
    @Relationship(inverse: \Stage.artifact) var stage: Stage?
    var type: ArtifactType         // text | code | file
    var content: String
    var filePath: String?          // path in ~/Documents/AgentOS/
    var createdAt: Date
}

// AgentConfig — configurable agent definition
@Model
class AgentConfig {
    var id: UUID
    var role: AgentRole
    var displayName: String
    var systemPrompt: String
    var model: String              // e.g. "claude-opus-4-6"
    var temperature: Double
    @Relationship(inverse: \Team.agents) var team: Team?
}

// Team — a named collection of AgentConfigs
@Model
class Team {
    var id: UUID
    var name: String
    @Relationship var agents: [AgentConfig]
    @Relationship var projects: [Project]
}
```

### Supporting Enums

```swift
enum ProjectStatus: String, Codable { case pending, running, completed, failed }
enum StageStatus: String, Codable { case pending, running, awaitingApproval, approved, failed, done }
enum AgentRole: String, Codable { case ceo, researcher, producer, reviewer, editor, ops, finance }
enum ArtifactType: String, Codable { case text, code, file }
```

---

## Agent Orchestrator

`AgentOrchestrator` is an `@MainActor` observable class (or actor for V1) that drives the Pipeline state machine.

### State Machine

```
Pipeline created
    ↓
[Stage: pending] → startStage() → [Stage: running]
    ↓ (AI call completes)
[Stage: running] → aiCallCompleted() → [Stage: awaitingApproval] (if gate on)
                                    → [Stage: done] (if yolo or gate off)
    ↓ (user approves)
[Stage: awaitingApproval] → userApproved() → [Stage: done]
    ↓
advanceToNextStage() → next Stage: pending → ...
    ↓ (all stages done)
Pipeline: completed
```

### Core Loop (Pseudocode)

```swift
func runPipeline(_ pipeline: Pipeline) async {
    for stage in pipeline.stages.sorted(by: \.sortOrder) {
        stage.status = .running
        let input = buildContext(for: stage, previousStages: completedStages)
        let result = try await aiProvider.complete(
            systemPrompt: stage.agentConfig.systemPrompt,
            userMessage: input,
            model: stage.agentConfig.model
        )
        stage.outputContent = result.content
        stage.costUSD = result.cost
        createArtifact(for: stage, content: result.content)
        
        if yoloMode {
            stage.status = .done
        } else {
            stage.status = .awaitingApproval
            await waitForUserApproval(stage)  // suspends until user taps Approve
        }
    }
    pipeline.project?.status = .completed
}
```

---

## AI Provider Abstraction

```swift
protocol AIProviderProtocol {
    func complete(
        systemPrompt: String,
        userMessage: String,
        model: String,
        temperature: Double
    ) async throws -> AIResponse
}

struct AIResponse {
    let content: String
    let inputTokens: Int
    let outputTokens: Int
    let costUSD: Double
}

// Concrete implementation for MVP
class ClaudeProvider: AIProviderProtocol {
    private let apiKey: String  // from Keychain
    
    func complete(...) async throws -> AIResponse {
        // URLSession call to https://api.anthropic.com/v1/messages
        // Parse response, calculate cost, return AIResponse
    }
}
```

**V1:** Add `OpenAIProvider` and `GeminiProvider` implementing the same protocol.  
**V2:** MCP tool calls added to `AIProviderProtocol`.

---

## Tool Layer (MVP)

Agents can invoke tools during their execution:

### Web Fetch Tool

```swift
struct WebFetchTool {
    func fetch(url: String) async throws -> String {
        // URLSession data task
        // Returns page text content (strip HTML tags)
        // Max 10,000 chars to avoid context overflow
    }
}
```

### File Export Service

```swift
class FileExportService {
    let baseDirectory = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("AgentOS")
    
    func export(artifact: Artifact, projectTitle: String) throws -> URL {
        // Creates ~/Documents/AgentOS/{projectTitle}/{artifactType}-{timestamp}.md
    }
}
```

---

## MVP Xcode Project Structure

```
mvp/AgentOS/
├── AgentOS.xcodeproj/
└── AgentOS/
    ├── App/
    │   ├── AgentOSApp.swift        ← @main, SwiftData ModelContainer setup
    │   └── ContentView.swift       ← NavigationSplitView (sidebar + detail)
    ├── Features/
    │   ├── Chat/
    │   │   ├── CEOChatView.swift
    │   │   └── CEOChatViewModel.swift
    │   ├── Pipeline/
    │   │   ├── PipelineBoardView.swift
    │   │   ├── StageCardView.swift
    │   │   └── PipelineViewModel.swift
    │   ├── Artifacts/
    │   │   ├── ArtifactsView.swift
    │   │   └── ArtifactDetailView.swift
    │   └── Team/
    │       ├── TeamView.swift
    │       └── AgentCardView.swift
    ├── Core/
    │   ├── Models/
    │   │   ├── Project.swift
    │   │   ├── Pipeline.swift
    │   │   ├── Stage.swift
    │   │   ├── Artifact.swift
    │   │   └── AgentConfig.swift
    │   ├── Services/
    │   │   ├── AgentOrchestrator.swift
    │   │   ├── AIProviderService.swift
    │   │   ├── WebFetchService.swift
    │   │   └── FileExportService.swift
    │   └── Extensions/
    │       └── String+Markdown.swift
    └── Resources/
        └── Assets.xcassets
```

---

## Security

- API keys stored in macOS Keychain (never in UserDefaults or plist)
- No telemetry or analytics in MVP
- File exports to sandboxed `~/Documents/AgentOS/` (requires entitlement for broader access)
- Web fetch: no cookies stored, no authentication, read-only

---

*Next: see `docs/agents/` for per-agent system prompts and specifications (index: `docs/agents/README.md`).*
