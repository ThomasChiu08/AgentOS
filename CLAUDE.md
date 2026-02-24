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
- Default: Claude (claude-opus-4-6 for CEO, claude-sonnet-4-6 for workers, claude-haiku-4-5 for fast tasks)
- No Python backend — Swift async/await + URLSession is sufficient for a client-only app

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
- **AI**: Anthropic Swift SDK (or direct API calls)
- **Concurrency**: Swift async/await + actors
- **Architecture**: MVVM with service layer

---

## Document Index

| Document | Path | Purpose |
|----------|------|---------|
| Product Design | `docs/plans/2026-02-24-agentos-product-design.md` | Full product spec, user flows, wireframes |
| Architecture | `docs/architecture.md` | Technical decisions, data models, module structure |
| Agent Roles | `docs/agent-roles.md` | System prompts and specs for all 7 agents |
| MVP Plan | `mvp/README.md` | MVP scope, milestones, done criteria |

---

## Core Data Models (SwiftData)

```swift
Project       { id, title, createdAt, status, teamId }
Pipeline      { id, projectId, stages: [Stage], edges: [(stageId, stageId)] }
Stage         { id, pipelineId, agentRole, status, inputContext, outputContent, costUSD, approved }
Artifact      { id, stageId, type, content, filePath, createdAt }
AgentConfig   { id, role, name, systemPrompt, model, temperature }
Team          { id, name, agents: [AgentConfig] }
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
    │   ├── Services/      (AgentOrchestrator, AIProviderService, WebFetchService, FileExportService)
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
