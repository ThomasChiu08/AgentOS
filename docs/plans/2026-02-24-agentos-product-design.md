# AgentOS — Product Design Document

**Date:** 2026-02-24  
**Author:** Thomas  
**Status:** Draft v1

---

## Executive Summary

AgentOS is a native macOS application that gives every solopreneur, indie creator, and one-person company a virtual AI team. Users describe a task in natural language, and a CEO agent automatically decomposes it into a Pipeline — a sequence of specialized AI agents that research, produce, review, format, and deliver the output autonomously.

> "Stop doing everything alone. Let your AI team handle it."

---

## Target Users

| Persona | Description | Primary Pain |
|---------|-------------|-------------|
| **Solopreneur** | Runs a 1-person business (consulting, SaaS, coaching) | Wears too many hats — strategy + execution + ops |
| **Indie Creator** | Content creator, Substack writer, YouTuber | Researching + writing + formatting takes all day |
| **Indie Developer** | Solo developer shipping apps | Writing, marketing, customer support on top of coding |
| **Freelancer** | High-value service provider | Proposal writing, research, follow-up communications |

**Core insight:** These users are already capable — they just need leverage. AgentOS provides that leverage without the overhead of managing a real team.

---

## Core Concepts

| Concept | Definition |
|---------|-----------|
| **Project** | A high-level goal ("Write a launch blog post for AgentOS") |
| **Pipeline** | Ordered stages that accomplish the Project |
| **Stage** | One agent's unit of work (research, write, review, format) |
| **Artifact** | The output of a Stage (text, code, file) |
| **Team** | The configured set of agents with their system prompts and models |
| **Human Gate** | A pause point where the user reviews and approves before proceeding |
| **Yolo Mode** | Pipeline runs fully autonomously — no Human Gates |

---

## User Flows

### Flow 1: Create a New Task

```
1. User opens AgentOS → CEO Chat is the default view
2. User types: "Write a launch article for my new iOS app"
3. CEO agent responds with a proposed Pipeline:
   - Stage 1: Researcher → gather recent iOS app launch best practices
   - Stage 2: Producer → draft 800-word article
   - Stage 3: QA Reviewer → review tone, accuracy, structure
   - Stage 4: Editor → format for Medium/Substack
4. User reviews Pipeline → clicks "Approve & Run" (or "Edit")
5. Pipeline begins executing
```

### Flow 2: Monitor Execution

```
1. User switches to Pipeline Board
2. See each Stage card with status: Pending / Running / Awaiting Approval / Done
3. Click any Stage card to see:
   - Agent's system prompt (what role it's playing)
   - Input context it received
   - Output it produced
   - Cost (tokens × price)
4. If Human Gate is enabled: "Approve" or "Request Revision" buttons appear
5. User approves → next Stage begins
```

### Flow 3: Review and Export Artifacts

```
1. User navigates to Artifacts panel
2. See all outputs organized by Project
3. Click any Artifact:
   - Preview full content
   - Copy to clipboard
   - Export as .md / .txt / .docx
   - Open in default app
4. Artifacts persist in ~/Documents/AgentOS/{ProjectTitle}/
```

---

## Feature List

| Feature | MVP | V1 | V2 |
|---------|-----|----|----|
| CEO Chat (natural language task entry) | ✅ | ✅ | ✅ |
| CEO auto-decomposes task into Pipeline | ✅ | ✅ | ✅ |
| Linear Pipeline execution | ✅ | ✅ | ✅ |
| Graph (parallel) Pipeline | ❌ | ✅ | ✅ |
| Human Approval Gate | ✅ | ✅ | ✅ |
| Yolo Mode (full auto) | ✅ | ✅ | ✅ |
| 4 core agents | ✅ | ✅ | ✅ |
| 7 agents | ❌ | ✅ | ✅ |
| Cost per stage display | ✅ | ✅ | ✅ |
| Cost budget limits | ❌ | ✅ | ✅ |
| File artifact export | ✅ | ✅ | ✅ |
| Agent configuration UI | ❌ | ✅ | ✅ |
| Multi-model support (GPT, Gemini) | ❌ | ✅ | ✅ |
| Agent Test Playground | ❌ | ✅ | ✅ |
| Web search tool (agents can browse) | ✅ | ✅ | ✅ |
| MCP tool protocol | ❌ | ❌ | ✅ |
| Shared RAG memory across agents | ❌ | ❌ | ✅ |
| Plugin / custom agent system | ❌ | ❌ | ✅ |
| Template Library | ❌ | ❌ | ✅ |
| Team sharing / collaboration | ❌ | ❌ | ✅ |

---

## Agent Roster

| # | Agent | Role Summary |
|---|-------|-------------|
| 1 | **CEO** | Interprets the user's goal and decomposes it into a Pipeline |
| 2 | **Researcher** | Searches the web, gathers data, analyzes competitors |
| 3 | **Producer** | Writes content, generates code, creates deliverables |
| 4 | **QA Reviewer** | Evaluates outputs for quality, accuracy, and coherence |
| 5 | **Editor** | Formats content for target platforms, polishes prose |
| 6 | **Operations** | Drafts customer communications, social media posts |
| 7 | **Finance** | Analyzes costs, checks compliance, summarizes financials |

*MVP includes agents 1–4. V1 adds 5–7.*

---

## Text Wireframes

### Screen 1: CEO Chat

```
┌──────────────────────────────────────────────────────┐
│ Sidebar           │ CEO Chat                          │
│ ─────────────     │ ─────────────────────────────     │
│ + New Project     │                                   │
│                   │  [System] Hi! I'm your CEO.       │
│ Recent Projects:  │  Describe a task and I'll build   │
│ • Launch Article  │  a team to handle it.             │
│ • Q1 Report       │                                   │
│ • Email Campaign  │  [User] Write a launch article    │
│                   │  for my new iOS app               │
│                   │                                   │
│                   │  [CEO] Here's my proposed plan:   │
│                   │                                   │
│                   │  Pipeline: iOS Launch Article     │
│                   │  ① Researcher → gather data       │
│                   │  ② Producer → draft article       │
│                   │  ③ QA Reviewer → review           │
│                   │  ④ Editor → format for Medium     │
│                   │                                   │
│                   │  Est. cost: ~$0.08                │
│                   │                                   │
│                   │  [Approve & Run] [Edit Pipeline]  │
│                   │                                   │
│                   │  ┌─────────────────────────────┐  │
│                   │  │ Type a task...          Send │  │
│                   │  └─────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
```

### Screen 2: Pipeline Board

```
┌──────────────────────────────────────────────────────┐
│ Pipeline: iOS Launch Article          [Yolo: OFF]     │
│                                                       │
│  ┌──────────────┐   ┌──────────────┐                 │
│  │ 🔍 Researcher │→  │ ✍️ Producer   │→  ...           │
│  │              │   │              │                 │
│  │ Status: Done │   │ Status: ⏳    │                 │
│  │ Cost: $0.012 │   │ Running...   │                 │
│  │              │   │              │                 │
│  │ [View Output]│   │              │                 │
│  └──────────────┘   └──────────────┘                 │
│                                                       │
│  ┌──────────────┐   ┌──────────────┐                 │
│  │ ✅ QA Review  │   │ 📝 Editor    │                 │
│  │              │   │              │                 │
│  │ Status: 🔒    │   │ Status: 🔒    │                 │
│  │ Pending Gate │   │ Pending      │                 │
│  │              │   │              │                 │
│  │              │   │              │                 │
│  └──────────────┘   └──────────────┘                 │
│                                                       │
│  Total Cost: $0.031 / $0.08 est.                     │
└──────────────────────────────────────────────────────┘
```

### Screen 3: Artifacts

```
┌──────────────────────────────────────────────────────┐
│ Artifacts                                             │
│                                                       │
│  Project: iOS Launch Article                         │
│  ─────────────────────────────────────────────────   │
│                                                       │
│  📄 Research Brief          [Researcher] 14:32        │
│     "Top strategies for iOS app launches in 2026..."  │
│     [Preview] [Copy] [Export .md]                    │
│                                                       │
│  📄 Draft Article           [Producer] 14:35          │
│     "How We Built AgentOS: A Solo Developer's..."     │
│     [Preview] [Copy] [Export .md]                    │
│                                                       │
│  📄 Review Notes            [QA Reviewer] —           │
│     Awaiting execution...                             │
│                                                       │
│  📄 Final Formatted         [Editor] —                │
│     Awaiting execution...                             │
│                                                       │
└──────────────────────────────────────────────────────┘
```

---

## Differentiation

| Dimension | AgentOS | CrewAI UI | AutoGPT | ChatGPT |
|-----------|---------|-----------|---------|---------|
| Native macOS app | ✅ | ❌ (web) | ❌ (web) | ❌ (web) |
| Non-technical UX | ✅ | ❌ (developer) | ❌ (developer) | ✅ |
| Structured roles | ✅ | ✅ | ❌ | ❌ |
| Human Gate control | ✅ | ❌ | partial | ❌ |
| Per-stage cost visibility | ✅ | ❌ | ❌ | ❌ |
| Offline-capable | future | ❌ | ❌ | ❌ |
| Persistent Artifacts | ✅ | ❌ | ❌ | partial |

**Key differentiator:** AgentOS is the only product that combines structured multi-agent pipelines with a consumer-grade, native macOS UX designed for non-technical solopreneurs.

---

## Yolo Mode Design

**Default (Human Gate ON):**
- Pipeline pauses after each Stage
- User sees the output and can: Approve / Request Revision / Stop
- Revision triggers a re-run of that Stage with feedback appended to context

**Yolo Mode (Human Gate OFF):**
- Toggle in toolbar or settings
- Pipeline runs from start to finish without pausing
- User receives a notification when complete
- All Artifacts available for review after run
- Designed for: trusted pipelines, repeatable workflows, overnight batch runs

**Safety:**
- Cost cap alert: warn user if projected cost exceeds set threshold (V1)
- Emergency stop: red "Stop Pipeline" button always visible
- Yolo mode is per-pipeline (not global setting) — must consciously enable

---

## Open Questions (for next iteration)

1. Should the CEO present a fixed Pipeline or have a back-and-forth planning conversation?
2. What's the minimal viable Agent Config UI for MVP? (just system prompt + model selector?)
3. Should Artifacts be stored in SwiftData or just the file system?
4. What's the right abstraction for Web Search — a tool the agents call, or a dedicated Stage?

---

*Document ends. Next: see `docs/architecture.md` for technical decisions.*
