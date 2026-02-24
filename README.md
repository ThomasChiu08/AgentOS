# AgentOS

> Give every solopreneur a virtual AI team of 7 specialized agents.

AgentOS is a native macOS application. Users describe a task in natural language via CEO Chat — the CEO agent automatically decomposes it into a Pipeline and assigns it to specialized agents that research, produce, review, and deliver.

## Versions

| Version | Status | Description |
|---------|--------|-------------|
| [mvp/](./mvp/) | 🚧 In Progress | 4 agents, linear Pipeline, concept validation |
| [v1/](./v1/) | ⬜ Planned | 7 agents, graph Pipeline, multi-model, cost tracking |
| [v2/](./v2/) | ⬜ Planned | MCP protocol, shared RAG memory, plugin system |

## Vision

Most solopreneurs are capable of incredible things — but they're bottlenecked by time. Researching, writing, reviewing, formatting, communicating — each task takes hours. AgentOS automates these workflows with a structured multi-agent system that works the way a real team would.

## Quick Start for Developers

```bash
# 1. Clone
git clone https://github.com/ThomasChiu08/AgentOS.git && cd AgentOS

# 2. Open MVP in Xcode
open mvp/AgentOS/AgentOS.xcodeproj

# 3. First run
# - Select the AgentOS scheme, choose "My Mac", press ⌘R
# - Go to Settings > API Keys and enter your Anthropic API key (stored in Keychain)
# - Start a task in CEO Chat to kick off your first Pipeline
```

**Requirements**: macOS 14+, Xcode 16+, Swift 5.10+

## Documentation

| Document | Description |
|----------|-------------|
| [CLAUDE.md](./CLAUDE.md) | Project memory — architecture decisions, conventions |
| [docs/plans/2026-02-24-agentos-product-design.md](./docs/plans/2026-02-24-agentos-product-design.md) | Full product design spec |
| [docs/architecture.md](./docs/architecture.md) | Technical architecture, data models |
| [docs/agents/](./docs/agents/) | Per-agent specs, system prompts, and roadmaps (index: [README](./docs/agents/README.md)) |

## Core Concepts

- **Project** — a goal the user wants to accomplish
- **Pipeline** — ordered stages that accomplish the Project
- **Stage** — one agent's unit of work
- **Artifact** — the persistent output of a Stage
- **Human Gate** — pause point for user approval (can be disabled with Yolo mode)

---

*Built 100% with Vibecoding using Claude Code.*
