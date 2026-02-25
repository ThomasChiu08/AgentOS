# AgentOS — Project Index

**Last Updated:** 2026-02-25
**Current Phase:** MVP Phase 2 — Complete ✅ | Next: Phase 3 Polish

> Quick-start guide for new sessions. Read this first, then follow links.

---

## Phase Status

### Phase 1 ✅ Complete — Xcode Skeleton

| Item | Status |
|------|--------|
| Xcode project created (PBXFileSystemSynchronizedRootGroup) | ✅ |
| `AgentOSApp.swift` with SwiftData ModelContainer | ✅ |
| `ContentView.swift` with NavigationSplitView | ✅ |
| All 5 SwiftData `@Model` classes | ✅ |
| All Feature Views (Chat, Pipeline, Artifacts, Team) | ✅ |
| Mock data for UI preview | ✅ |
| Build succeeds (macOS 14+) | ✅ |

### Phase 2 ✅ Complete — Backend Services + SwiftData Integration

#### Backend Services

- [x] `KeychainHelper.swift` — API key read/write
- [x] `AIProviderService.swift` — Protocol + ClaudeProvider + OpenAICompatibleProvider; 30s timeout; `.timeout` error case
- [x] `WebFetchService.swift` — URLSession wrapper, HTML → plain text
- [x] `FileExportService.swift` — Export to `~/Documents/AgentOS/`
- [x] `PipelineParser.swift` — CEO JSON output → Pipeline + Stage[]
- [x] `AgentOrchestrator.swift` — Pipeline state machine actor; persists `.failed` status on error
- [x] `QAOutputParser.swift` — Regex-extracts score and recommendation from QA output

#### Frontend Integration

- [x] `CEOChatViewModel` → real API + SwiftData; pre-flight API key check; `loadProject()` for history
- [x] `PipelineBoardView` → `@Query` real Stages; error banner on pipeline failure
- [x] `ArtifactsView` → `@Query` real Artifacts (sorted by `createdAt` desc)
- [x] `TeamView` → `@Query` real AgentConfigs
- [x] `SettingsView.swift` — API key input + Yolo default toggle
- [x] `ModelQuickPicker` — compact CEO model switcher; checkmark + Switch Provider submenu
- [x] `ModelTierBadge` — Speed/Balanced/Power + Custom badge for arbitrary model names
- [x] `ProjectListView` — project history sidebar in `HSplitView` alongside CEO Chat
- [x] `AgentConfigEditorView` — custom model name TextField + ModelTierBadge

#### Beyond Original Scope (shipped in Phase 2)

- [x] Multi-provider support — Anthropic, OpenAI-compatible, Ollama, Gemini, DeepSeek, Groq, etc.
- [x] Custom model name input — arbitrary `modelIdentifier: String` (not locked to enum)
- [x] Structured agent output formats — Researcher/Producer/QA output schemas
- [x] QA score badge on StageCardView — colored X/10 display

#### End-to-End

- [ ] 5 real-task end-to-end tests (smoke test with real API key)

### Phase 3 🔄 In Progress — Polish & Distribution

- [ ] Error handling hardening (retry, partial failure recovery)
- [ ] Empty states for all views
- [ ] Cost tracking dashboard
- [ ] Pipeline templates
- [ ] Yolo mode — full end-to-end auto-run verification
- [ ] App Store submission prep

---

## File Index

### Documentation

| File | Purpose |
|------|---------|
| `docs/plans/2026-02-24-agentos-product-design.md` | Full product spec, user flows, UX wireframes |
| `docs/architecture.md` | Tech stack, data models, orchestrator design |
| `docs/agents/` | Per-agent specs, system prompts, and roadmaps (index: `docs/agents/README.md`) |
| `docs/plans/mvp-phase2-backend-design.md` | Phase 2 backend services spec (this phase) |
| `docs/plans/mvp-phase2-frontend-design.md` | Phase 2 frontend SwiftData integration spec (this phase) |
| `mvp/README.md` | MVP scope, milestones, done criteria |
| `tasks/index.md` | This file — project index and phase tracker |

### Swift Source Files

#### App Layer

| File | Purpose |
|------|---------|
| `mvp/AgentOS/AgentOS/AgentOSApp.swift` | `@main`, SwiftData ModelContainer setup |
| `mvp/AgentOS/AgentOS/ContentView.swift` | Root NavigationSplitView, SidebarItem routing |

#### Features

| File | Purpose |
|------|---------|
| `Features/Chat/CEOChatView.swift` | Chat UI: message list + input bar |
| `Features/Chat/CEOChatViewModel.swift` | Observable VM: mock sendMessage (Phase 2: real) |
| `Features/Pipeline/PipelineBoardView.swift` | Pipeline board with Stage cards |
| `Features/Pipeline/PipelineViewModel.swift` | Mock stage list (Phase 2: @Query) |
| `Features/Pipeline/StageCardView.swift` | Individual stage card + status badge |
| `Features/Artifacts/ArtifactsView.swift` | Artifact list (Phase 2: @Query) |
| `Features/Artifacts/ArtifactDetailView.swift` | Artifact content viewer + copy/export |
| `Features/Team/TeamView.swift` | Agent config list (Phase 2: @Query) |
| `Features/Team/AgentCardView.swift` | Individual agent card |

#### Core Models (SwiftData)

| File | Model | Key Fields |
|------|-------|-----------|
| `Core/Models/Project.swift` | `Project` | id, title, createdAt, status, pipeline?, team? |
| `Core/Models/Pipeline.swift` | `Pipeline` | id, yoloMode, stages[], project? |
| `Core/Models/Stage.swift` | `Stage` | id, agentRole, status, position, inputContext, outputContent, costUSD, approved, artifacts[] |
| `Core/Models/Artifact.swift` | `Artifact` | id, type, title, content, filePath?, createdAt, stage? |
| `Core/Models/AgentConfig.swift` | `AgentConfig` | id, role, displayName, systemPrompt, model, temperature, team? |

#### Core Services (Phase 2 — to be created)

| File | Purpose |
|------|---------|
| `Core/Services/AIProviderService.swift` | `AIProviderProtocol` + `ClaudeProvider` |
| `Core/Services/AgentOrchestrator.swift` | Pipeline state machine `@MainActor` class |
| `Core/Services/WebFetchService.swift` | URL → plain text fetcher |
| `Core/Services/FileExportService.swift` | Artifact → `~/Documents/AgentOS/` |
| `Core/Utilities/KeychainHelper.swift` | API key Keychain read/write |
| `Core/Utilities/PipelineParser.swift` | CEO JSON → SwiftData Pipeline/Stage |

#### Core Extensions

| File | Purpose |
|------|---------|
| `Core/Extensions/String+Markdown.swift` | Markdown rendering helpers |

---

## Key Architectural Decisions

### Why PBXFileSystemSynchronizedRootGroup?
Xcode 16 feature: auto-discovers Swift files in the directory — no manual "Add Files" needed. New files added to disk appear in Xcode automatically. Requires Xcode 16+.

### Xcode Version
16.x (macOS Sequoia compatible). Build succeeds for macOS 14.0+ deployment target.

### No Python Backend
Pure Swift client: URLSession + async/await for all AI API calls. API keys stay on device in Keychain. Eliminates server maintenance and deployment complexity.

### SwiftData over Core Data
macOS 14+ target means SwiftData is available. `@Model` macro reduces boilerplate. `@Query` gives reactive UI updates automatically.

### `@MainActor` for Orchestrator
AgentOrchestrator runs on main actor so SwiftData mutations and SwiftUI updates are always on main thread. Async AI calls are naturally offloaded to background via Swift concurrency.

### StageStatus Enum Values
`waiting → running → completed → approved` (happy path)
`waiting → running → failed` (error path)
`completed` = AI done, awaiting human approval (non-yolo mode)
`approved` = human approved OR yolo auto-approved

---

## Phase 2 Implementation Order

Implement in this sequence (each step unblocks the next):

1. **`KeychainHelper.swift`** — No dependencies. Foundation for API key storage.
2. **`AIProviderService.swift`** — Depends on Keychain. Core AI call capability.
3. **`WebFetchService.swift`** — No dependencies. Researcher agent tool.
4. **`FileExportService.swift`** — No dependencies. Post-stage artifact export.
5. **`PipelineParser.swift`** — No service dependencies. Pure data transform.
6. **`AgentOrchestrator.swift`** — Depends on all above services.
7. **Connect `CEOChatViewModel`** — Depends on Orchestrator + PipelineParser.
8. **Connect `PipelineBoardView`** — `@Query` stages, Approve/Reject buttons.
9. **`SettingsView.swift`** (new) — API key input UI, Yolo default toggle.
10. **End-to-end tests** — 5 real tasks, verify full pipeline execution.

---

## Design Documents (Phase 2)

- **Backend spec:** `docs/plans/mvp-phase2-backend-design.md`
- **Frontend spec:** `docs/plans/mvp-phase2-frontend-design.md`

Both documents are self-contained and can be used as PR descriptions or as direct implementation guides.
