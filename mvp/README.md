# AgentOS — MVP

> Validate the core idea: can a non-technical user orchestrate a multi-agent Pipeline via natural language?

## MVP Goal (One Line)

Ship a macOS app where a user can describe a task in natural language and watch 4 AI agents execute it step-by-step.

## Included in MVP

- **CEO Chat** — natural language task entry, Pipeline proposal by CEO agent
- **4 Agents** — CEO, Researcher, Producer, QA Reviewer
- **Linear Pipeline** — sequential stage execution (no parallel branches)
- **Human Approval Gate** — pause after each Stage, user approves before proceeding
- **Yolo Mode** — toggle to skip gates and run fully autonomously
- **Cost Display** — show token cost per Stage and total Pipeline cost
- **Artifact Export** — save outputs to `~/Documents/AgentOS/` as `.md` files
- **Web Fetch Tool** — Researcher can fetch URLs during execution

## Not Included in MVP

- Multiple AI providers (GPT, Gemini) — Claude only
- Agent configuration UI — prompts are hardcoded
- Parallel (graph) Pipeline execution
- Cost budgets / alerts
- Retry / revision loops (user must re-run manually)
- PDF / file upload
- Agents 5–7 (Editor, Operations, Finance)
- Sharing or collaboration

## Xcode Project Setup

1. Open Xcode → File → New → Project
2. Choose: macOS → App
3. Product Name: `AgentOS`
4. Bundle ID: `com.thomas.agentos`
5. Interface: SwiftUI | Life Cycle: SwiftUI App | Storage: SwiftData
6. Minimum Deployment: macOS 14.0
7. Save to: `AgentOS/mvp/`

## MVP File Structure

```
mvp/AgentOS/
├── AgentOS.xcodeproj/
└── AgentOS/
    ├── App/
    │   ├── AgentOSApp.swift        ← SwiftData ModelContainer setup
    │   └── ContentView.swift       ← NavigationSplitView root
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

## Development Milestones

### Phase 1: Skeleton (Days 1–2)
- [ ] Xcode project initialized with SwiftData
- [ ] All SwiftData `@Model` classes created and compiling
- [ ] NavigationSplitView with 3 panels (sidebar, pipeline, artifacts)
- [ ] Hardcoded mock data displays in all views
- [ ] Build succeeds with zero warnings

### Phase 2: Core Functionality (Days 3–7)
- [ ] Claude API integrated (via Keychain-stored API key)
- [ ] CEO Chat: user message → CEO agent → Pipeline proposal displayed
- [ ] Pipeline Board: Stage cards with live status updates
- [ ] AgentOrchestrator state machine running through stages
- [ ] Human Gate: Approve / Reject buttons working
- [ ] Yolo mode toggle functional
- [ ] Artifacts written to `~/Documents/AgentOS/`
- [ ] Cost per stage calculated and displayed

### Phase 3: Polish (Days 8–10)
- [ ] Error handling: API failures, network errors shown in UI
- [ ] Empty states for all views
- [ ] Loading indicators during AI calls
- [ ] Settings view: enter API key, toggle Yolo default
- [ ] Test with 5 real tasks end-to-end
- [ ] Fix all issues found in real testing

## Definition of Done

MVP is complete when a non-technical user can:
1. Open the app and enter an API key
2. Type a task in CEO Chat
3. Watch 4 agents execute the Pipeline with visible progress
4. Approve each stage (or run in Yolo mode)
5. Find their output files in `~/Documents/AgentOS/`

...without encountering any crashes or confusing errors.
