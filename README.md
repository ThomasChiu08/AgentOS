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

## Documentation

| Document | Description |
|----------|-------------|
| [CLAUDE.md](./CLAUDE.md) | Project memory — architecture decisions, conventions |
| [docs/plans/2026-02-24-agentos-product-design.md](./docs/plans/2026-02-24-agentos-product-design.md) | Full product design spec |
| [docs/architecture.md](./docs/architecture.md) | Technical architecture, data models |
| [docs/agent-roles.md](./docs/agent-roles.md) | All 7 agent specs with system prompts |

## Core Concepts

- **Project** — a goal the user wants to accomplish
- **Pipeline** — ordered stages that accomplish the Project
- **Stage** — one agent's unit of work
- **Artifact** — the persistent output of a Stage
- **Human Gate** — pause point for user approval (can be disabled with Yolo mode)
