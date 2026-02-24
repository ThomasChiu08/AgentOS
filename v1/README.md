# AgentOS — v1

> Goal: Build on MVP learnings to ship a stable, polished product with the full 7-agent team and intelligent pipeline routing.

## New in v1

### Full 7-Agent Team

| # | Role | Model | Primary Task |
|---|------|-------|-------------|
| 1 | CEO | claude-opus-4-6 | Pipeline decomposition & strategy |
| 2 | Researcher | claude-sonnet-4-6 | Web search, competitive analysis |
| 3 | Producer | claude-sonnet-4-6 | Content creation, code writing |
| 4 | QA Reviewer | claude-sonnet-4-6 | Quality review, improvement suggestions |
| 5 | Editor/Formatter | claude-haiku-4-5 | Format, polish, platform adaptation |
| 6 | Operations/CX | claude-haiku-4-5 | Customer communication, social drafts |
| 7 | Finance/Compliance | claude-haiku-4-5 | Cost analysis, compliance checks |

### Graph Pipeline

- Parallel branch execution — stages that don't depend on each other run concurrently
- CEO agent produces a DAG (Directed Acyclic Graph) instead of a linear list
- Pipeline Board visualizes branches and merges
- Merge nodes aggregate outputs from parallel branches before continuing

### Multi-Model Support

- `AIProviderProtocol` backed by Claude, GPT-4o, and Gemini Pro
- Per-agent model selection in Team configuration UI
- Model fallback: if primary provider fails, retry with fallback
- Cost calculation updated for each provider's pricing

### Cost Tracking

- Per-stage token cost displayed in real time
- Pipeline total cost shown in Pipeline Board header
- Cost budget: set a USD limit per pipeline run
- Cost alert: notify (and optionally pause) when budget is 80% used
- Historical cost report: total spend per project, per week

### Agent Test Playground

- Isolated sandbox to test a single agent without running a full Pipeline
- Input arbitrary context, inspect raw output and token usage
- Tweak system prompt and model parameters, compare results side by side
- Useful for tuning agent prompts before deploying to production

## Improvements from MVP

| Area | MVP | v1 |
|------|-----|----|
| Agents | 4 (CEO, Researcher, Producer, QA) | 7 (+ Editor, Operations, Finance) |
| Pipeline shape | Linear (sequential) | Graph (parallel branches) |
| AI providers | Claude only | Claude + GPT-4o + Gemini |
| Cost | Display only | Budgets + alerts + history |
| Agent config | Hardcoded prompts | Full UI configuration |
| Retry/revision | Manual re-run | Automatic retry loops (configurable) |
| File input | None | PDF and text file upload |
| Error handling | Basic | Graceful degradation + user-readable messages |

## v1 Milestones

### Phase 1: Expand Agent Team (MVP + 3)
- [ ] Editor/Formatter agent implemented and tested
- [ ] Operations/CX agent implemented and tested
- [ ] Finance/Compliance agent implemented and tested
- [ ] Agent config UI: name, system prompt, model, temperature per agent
- [ ] Team view shows all 7 agents with editable config

### Phase 2: Graph Pipeline Engine
- [ ] CEO agent outputs DAG structure (JSON with nodes + edges)
- [ ] AgentOrchestrator executes parallel stages with Swift concurrency
- [ ] Pipeline Board renders graph layout (nodes, edges, parallel lanes)
- [ ] Merge node logic: waits for all upstream stages before proceeding
- [ ] Human Gate works at branch boundaries and merge points

### Phase 3: Multi-Model Integration
- [ ] `AIProviderProtocol` extended with GPT and Gemini implementations
- [ ] Per-agent provider selection persisted in SwiftData
- [ ] API key management for all three providers (Keychain)
- [ ] Model fallback chain configured in Settings

### Phase 4: Cost Tracking & Reporting
- [ ] Real-time token cost calculated per stage
- [ ] Pipeline budget input in CEO Chat
- [ ] Cost alert at 80% threshold (notification + optional pause)
- [ ] Cost history view: per project, per week
- [ ] Export cost report as CSV

### Phase 5: Agent Test Playground
- [ ] Standalone playground view in sidebar
- [ ] Select agent, enter custom context, run in isolation
- [ ] Side-by-side prompt comparison
- [ ] Token usage breakdown displayed

## Definition of Done

v1 is complete when:
1. A user can run a 7-agent parallel Pipeline on a real task
2. Cost stays within a user-set budget (auto-pause on exceeded budget)
3. Any agent's model can be swapped to GPT or Gemini without code changes
4. A new agent can be defined entirely through the UI, no code required
5. The app handles API failures gracefully with retry and user notification

## Notes

<!-- Decisions, tradeoffs, learnings from MVP → v1 transition -->
