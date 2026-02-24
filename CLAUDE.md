# AgentOS — Project Memory

## Vision

AgentOS is a native macOS app that gives solopreneurs and indie creators a **virtual AI team of 7 agents**. Users describe a task in natural language via CEO Chat, and the system automatically decomposes it into a Pipeline distributed across specialized agents.

> "Every individual deserves an AI team working for them."

---

## Key Design Decisions

### Hybrid Interaction Model
- **CEO Chat**: Natural language task entry — conversational, zero friction
- **Pipeline Board**: Visual execution tracking — see what each agent is doing
- **Artifacts Panel**: Browse and export outputs — documents, code, reports

### Yolo Mode
- Default: Human Approval Gate at each stage boundary
- Yolo mode: Full automation, no interruptions — for trusted, repeatable workflows

### AI Provider Strategy
- Abstracted via `AIProviderProtocol` — swap Claude / GPT / Gemini per agent
- Direct Anthropic API via URLSession + Streaming (SSE) — no third-party SDK dependency
- No Python backend — Swift async/await + actors is sufficient for a client-only app

| Agent Role | Model | Rationale |
|-----------|-------|-----------|
| CEO | `claude-opus-4-6` | Deepest reasoning for decomposition |
| Researcher, Producer, QA | `claude-sonnet-4-6` | Best coding + analysis |
| Fast/utility tasks | `claude-haiku-4-5-20251001` | Low latency, cost-efficient |

```swift
actor AnthropicService {
    private let apiKey: String
    private let baseURL = URL(string: "https://api.anthropic.com/v1")!

    func stream(messages: [Message], model: String) -> AsyncThrowingStream<String, Error> {
        // SSE streaming via URLSession data task with delegate
    }

    func complete(messages: [Message], model: String) async throws -> String {
        // Non-streaming for simple structured calls
    }
}
```

---

## Version Roadmap

| Version | Directory | Status | Goal |
|---------|-----------|--------|------|
| MVP | `mvp/` | In Progress | 4 agents, linear pipeline, concept validation |
| v1 | `v1/` | Planned | 7 agents, graph pipeline, multi-model, cost tracking |
| v2 | `v2/` | Planned | MCP protocol, shared RAG memory, plugin system |

---

## Tech Stack

- **UI**: SwiftUI (macOS 14+)
- **Storage**: SwiftData
- **Networking**: URLSession (no Alamofire dependency)
- **AI**: Direct Anthropic API via URLSession + Streaming (SSE)
- **Concurrency**: Swift async/await + actors
- **Architecture**: MVVM with service layer

---

## macOS Compliance & Security Checklist

### Required Entitlements (App Sandbox)

```xml
<!-- AgentOS.entitlements -->
<key>com.apple.security.app-sandbox</key>       <true/>
<key>com.apple.security.network.client</key>    <true/>
<key>com.apple.security.keychain-access-groups</key>
<array><string>$(AppIdentifierPrefix)com.thomas.agentos</string></array>
```

### Info.plist Privacy Keys

Add only keys for features actually used — don't preemptively add all:

```xml
<!-- Only if using AppleScript automation in v1+ -->
<key>NSAppleEventsUsageDescription</key>
<string>AgentOS needs AppleEvents to automate tasks on your behalf.</string>
```

### API Key Storage (Keychain)

Never store secrets in `UserDefaults` or source files:

```swift
// Core/Services/KeychainService.swift
enum KeychainService {
    static func save(apiKey: String, for provider: String) throws {
        let data = Data(apiKey.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.thomas.agentos.\(provider)",
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary) // overwrite if exists
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }

    static func load(for provider: String) throws -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "com.thomas.agentos.\(provider)",
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8)
        else { throw KeychainError.notFound }
        return key
    }
}
```

### Sandbox Considerations (MVP)

- **Allowed**: `network.client` (Anthropic API, WebFetch), keychain access
- **Not needed for MVP**: file access (add `.bookmarks` entitlement only when exporting)
- **Distribution**: App Sandbox required for Mac App Store; add it anyway for security hygiene

---

## Document Index

| Document | Path | Purpose |
|----------|------|---------|
| Product Design | `docs/plans/2026-02-24-agentos-product-design.md` | Full product spec, user flows, wireframes |
| Architecture | `docs/architecture.md` | Technical decisions, data models, module structure |
| Agent Directory | `docs/agents/` | Per-agent specs, system prompts, and roadmaps (index: `docs/agents/README.md`) |
| MVP Plan | `mvp/README.md` | MVP scope, milestones, done criteria |

---

## Core Data Models (SwiftData)

```swift
// Stage execution state — stored as rawValue String in SwiftData
enum StageStatus: String, Codable {
    case pending, running, completed, failed, skipped
}

Project         { id, title, createdAt, status: String, teamId: UUID }
Pipeline        { id, projectId, stages: [Stage], edges: [(UUID, UUID)]? }  // nil = linear (MVP default)
Stage           { id, pipelineId, agentRole, status: StageStatus,
                  inputContext, outputContent: String?, costUSD: Double, approved: Bool }
Artifact        { id, stageId, type, content, filePath: String?, createdAt }
AgentConfig     { id, role, name, systemPrompt, model, temperature: Double }
Team            { id, name, agents: [AgentConfig] }
UserPreferences { id: UUID, yoloMode: Bool, theme: String, apiKeyHash: String? }  // singleton
```

---

## MVP Xcode Project

Path: `mvp/AgentOS/`
Bundle ID: `com.thomas.agentos`
Minimum macOS: 14.0

```
mvp/AgentOS/
├── AgentOS.xcodeproj
└── AgentOS/
    ├── App/
    │   ├── AgentOSApp.swift
    │   └── ContentView.swift
    ├── Features/
    │   ├── Chat/          (CEOChatView + ViewModel)
    │   ├── Pipeline/      (PipelineBoardView + StageCardView + ViewModel)
    │   ├── Artifacts/     (ArtifactsView + ArtifactDetailView)
    │   └── Team/          (TeamView + AgentCardView)
    ├── Core/
    │   ├── Models/        (SwiftData @Model classes)
    │   ├── Services/      (AgentOrchestrator, AnthropicService, KeychainService,
    │   │                   WebFetchService, FileExportService)
    │   └── Extensions/
    └── Resources/
```

---

## Agent Roster (MVP: 4 of 7)

| # | Role | Model | Primary Task |
|---|------|-------|-------------|
| 1 | CEO | claude-opus-4-6 | Pipeline decomposition |
| 2 | Researcher | claude-sonnet-4-6 | Web search, competitive analysis |
| 3 | Producer | claude-sonnet-4-6 | Content creation, code writing |
| 4 | QA Reviewer | claude-sonnet-4-6 | Quality review, improvement suggestions |

V1 adds: Editor/Formatter, Operations/CX, Finance/Compliance

---

## UI/UX Guidelines

### macOS 15 Design Language
- **Materials**: `.ultraThinMaterial` / `.regularMaterial` for sidebars and panels
- **Vibrancy**: `NSVisualEffectView` for window chrome; avoid flat opaque backgrounds
- **Typography**: SF Pro (system font) — use `.title`, `.headline`, `.caption` semantics
- **Icons**: SF Symbols 6 — prefer `Image(systemName:)` over custom assets
- **Animations**: `.spring(response: 0.35, dampingFraction: 0.7)` as default motion curve
- **Color**: Semantic colors only (`.primary`, `.accentColor`) — auto-adapts to light/dark

### CEO Chat Layout
- `NavigationSplitView`: sidebar for project history, detail for active chat + pipeline
- Chat input pinned at bottom; messages scroll upward
- Compact popover variant for quick task entry (global shortcut: ⌘⇧Space)

### Pipeline Board Layout
- Horizontal scrollable `HStack` of `StageCard` views inside `ScrollView(.horizontal)`
- Each card: SF Symbol avatar, role name, status badge, live token counter
- Stage connections: subtle dashed arrows, animated while stage is running
- Status colors: `.blue` running · `.green` done · `.orange` waiting · `.red` failed

---

## Working Conventions

- No force unwrap (`!`) anywhere
- SwiftData `@Model` classes: one per file in `Core/Models/`
- Services are actors or use `@MainActor` where appropriate
- File size limit: 200 lines; split if larger
- Commit format: `feat/fix/refactor/docs/chore: description`

---

## Workflow Orchestration

### 1. Plan Mode Default
- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately — don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

### 2. Subagent Strategy
- Use subagents liberally to keep main context window clean
- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One task per subagent for focused execution

### 3. Self-Improvement Loop
- After ANY correction from the user: update `tasks/lessons.md` with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

### 4. Verification Before Done
- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

### 5. Demand Elegance (Balanced)
- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes — don't over-engineer
- Challenge your own work before presenting it

### 6. Autonomous Bug Fixing
- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests — then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

---

## Task Management

1. **Plan First**: Write plan to `tasks/todo.md` with checkable items
2. **Verify Plan**: Check in before starting implementation
3. **Track Progress**: Mark items complete as you go
4. **Explain Changes**: High-level summary at each step
5. **Document Results**: Add review section to `tasks/todo.md`
6. **Capture Lessons**: Update `tasks/lessons.md` after corrections

---

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
