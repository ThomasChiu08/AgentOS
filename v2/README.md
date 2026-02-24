# AgentOS — v2

> Goal: Transform AgentOS from a personal tool into an open platform — extensible via plugins, connected to external tools via MCP, and enhanced with persistent shared memory across projects.

## New in v2

### MCP Tool Protocol

- Agents connect to external tools via the [Model Context Protocol](https://modelcontextprotocol.io/)
- Built-in MCP servers: filesystem, web browser, code executor, calendar
- Community MCP servers: GitHub, Notion, Slack, Figma, Linear, and more
- Users install MCP servers from a curated marketplace in the app
- Each agent's tool access is configurable (principle of least privilege)

### Shared RAG Memory

- Cross-project vector store: agents accumulate knowledge over time
- Memory types:
  - **Episodic** — what happened in past pipelines (summaries, outcomes)
  - **Semantic** — facts the user has taught agents (preferences, context, style guide)
  - **Procedural** — learned workflows ("for this client, always follow X format")
- Memory is queryable via natural language in CEO Chat ("use my previous research on X")
- Privacy controls: per-project memory isolation or shared pool

### Plugin System

- Open plugin API: third-party developers can add new agent types
- Plugin manifest: name, description, system prompt template, tools, models
- Plugin distribution: local file import or verified marketplace
- Sandboxing: plugins run in isolated context, no access to other agents' outputs without permission
- AgentOS ships with first-party plugins: Social Media Pack, Developer Pack, Research Pack

### Template Library

- Save any successful Pipeline as a reusable template
- Template variables: `{{client_name}}`, `{{industry}}`, `{{tone}}` etc.
- Browse community-contributed templates in-app
- One-click instantiation: fill variables, run immediately
- Templates versioned — update without breaking existing projects

### Collaboration (Team Sharing)

- Share a Team configuration (agent roster + system prompts) via export/import
- Read-only sharing: export team as `.agentos-team` file
- Pipeline sharing: export a completed Pipeline with artifacts as a report
- Future (post-v2): real-time collaboration with shared workspace

## Improvements from v1

| Area | v1 | v2 |
|------|----|----|
| Tool access | Built-in (web fetch, file export) | MCP protocol — unlimited external tools |
| Memory | Per-session only | Persistent RAG across projects |
| Extensibility | Fixed 7-agent roster | Plugin system — add any agent type |
| Reusability | Manual re-creation | Template library with variables |
| Sharing | None | Team + Pipeline export/import |
| Community | None | Marketplace for plugins and templates |

## v2 Milestones

### Phase 1: MCP Integration
- [ ] MCP client embedded in AgentOS (Swift MCP client library)
- [ ] Built-in MCP servers: filesystem read/write, web browse, run-shell
- [ ] MCP server management UI: install, enable/disable per agent
- [ ] Each tool call logged in Stage detail view

### Phase 2: RAG Memory Layer
- [ ] Vector database integrated (local, on-device — e.g., SQLite with embeddings)
- [ ] Memory ingestion: completed Pipeline summaries auto-saved
- [ ] Memory retrieval: CEO agent queries memory at Pipeline start
- [ ] User-managed semantic facts: add/edit/delete via Settings
- [ ] Memory privacy controls: project-scoped vs. global

### Phase 3: Plugin System
- [ ] Plugin manifest spec defined (JSON schema)
- [ ] Plugin loader: reads manifest, registers agent type
- [ ] Plugin sandbox: tool access limited to manifest-declared tools
- [ ] First-party plugins: Social Media Pack, Developer Pack
- [ ] In-app plugin browser (local import first, marketplace later)

### Phase 4: Template Library
- [ ] "Save as Template" action on any completed Pipeline
- [ ] Template variable extraction from Pipeline context
- [ ] Template browser view with preview
- [ ] One-click run with variable input form
- [ ] Export/import templates as `.agentos-template` files

### Phase 5: Sharing & Export
- [ ] Team export as `.agentos-team` file
- [ ] Team import with merge/replace options
- [ ] Pipeline report export (Markdown + Artifacts bundle)
- [ ] Community template submission flow (optional future)

## Architecture Changes from v1

```
v1: Agent → AIProviderService → LLM API
v2: Agent → AIProviderService + MCPClient → LLM API + External Tools
                                ↕
                          RAGMemoryStore (local vector DB)
                                ↕
                         PluginRegistry (dynamic agent types)
```

## Definition of Done

v2 is complete when:
1. A user can connect an MCP server (e.g., GitHub) and have agents use it without writing code
2. The CEO agent references memory from a previous project when relevant
3. A third-party plugin can be installed and run as a full agent in a Pipeline
4. A recurring Pipeline can be saved as a template and re-run in under 30 seconds
5. A user can share their team configuration with a colleague via a single file

## Notes

<!-- Decisions, tradeoffs, learnings from v1 → v2 transition -->
