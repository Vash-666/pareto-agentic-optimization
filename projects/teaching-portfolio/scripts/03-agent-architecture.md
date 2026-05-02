# 6 Agents, 1 Purpose: Multi-Agent Architecture

**Duration:** ~5 minutes
**Format:** Short-form technical explainer
**Target:** AI engineers, system architects, technical recruiters

---

## Situation

A single AI assistant handles general tasks competently, but faces three hard limits:

1. **Context constraints** — One model cannot hold all the context needed for complex multi-step workflows
2. **Specialization limits** — The best model for reasoning (Claude Sonnet) is not the best for cost (DeepSeek), search (Perplexity), or analysis (Grok)
3. **Quality blind spots** — The agent writing the code cannot reliably audit its own work — there is an inherent conflict of interest

We were running a solo-agent system that tried to do everything: plan the work, generate content, review it for quality, commit to GitHub, and monitor results. The output was inconsistent. Quality suffered because the agent couldn't see its own blind spots. Tasks that required 3 specialized strengths (e.g., research + writing + quality check) were handled by one model performing suboptimally at all three.

## Task

Design a multi-agent architecture where each agent has a clear role, a specialized model, and an independent quality gate. The system needed to:

- Eliminate single points of failure (no agent blocks on another agent's failure)
- Ensure independent quality auditing (reviewer != author)
- Optimize cost by assigning models to appropriate tasks
- Scale from 3 to N agents without architectural changes
- Maintain full observability (any agent's work is inspectable)

## Action

We built a 6-agent system with distinct responsibilities.

### Agent Roles

**Switch (Orchestrator)** — Model: Claude Sonnet
- Routes tasks to the appropriate agent based on type and complexity
- Maintains the shared SESSION-CONTEXT.md for inter-agent state transfer
- Handles routing decisions using the 80/20 model-switching protocol
- Does not execute work — only coordinates

**QualityGuardian (Auditor)** — Model: DeepSeek
- Independently scores all outputs using the Quality Equation
- Operates as a separate process — cannot be influenced by the producing agent
- Blocks any output that fails the milestone threshold
- Maintains the quality score history for trend analysis

**Content (Writer)** — Model: Claude Sonnet
- Generates scripts, guides, and documentation
- Works from structured templates with required sections
- Produces outputs with concrete metrics and verifiable claims

**Grok (Research)** — Model: Perplexity / Grok
- Researches topics and gathers reference materials
- Validates factual claims before content generation
- Maintains a reference library of source materials

**Product (Product Manager)** — Model: DeepSeek
- Defines task scope, priorities, and acceptance criteria
- Tracks project state and milestone completion
- Handles task breakdown and dependency mapping

**Scaffolder (Infrastructure)** — Model: DeepSeek
- Creates and maintains files, directories, and tool configurations
- Runs pipeline scripts and auto-publish commands
- Monitors system health and tool availability

### Quality Gates

Every milestone has a gate that blocks progression until the minimum score is met:

| Milestone | Min Score | Gate Keeper |
|---|---|---|
| Start | 60/100 | Scaffolder (self-check) |
| Review | 75/100 | QualityGuardian (independent) |
| Complete | 85/100 | QualityGuardian (independent) |
| Production | 90/100 | QualityGuardian + Switch audit |

### Communication Protocol

Agents communicate through two channels:
1. **SESSION-CONTEXT.md** — Shared state file read by all agents
2. **Tool outputs** — Agents pass artifacts through the filesystem, not through model context

This avoids context window limits and ensures any agent can pick up where another left off.

## Result

- **6 agents** with distinct specializations and model assignments
- **39 files** generated across teaching-portfolio and supporting tooling
- **8 tools** integrated: quality gate, context store, pipeline, auto-publish, batch processor, visibility log, router agent, report generator
- **7-step pipeline** that runs from task definition to GitHub publication
- **88% cost savings** compared to using Claude Sonnet for all tasks (DeepSeek handles 80% of routing work)

The architecture scales cleanly. Adding a new agent means defining its role, model, and gate threshold — the communication and routing protocols remain unchanged.

---

## Key Metrics

| Metric | Solo Agent | 6-Agent System | Change |
|---|---|---|---|
| Agent count | 1 | 6 | +500% |
| Files per project | 5-8 | 39 | +400% |
| Tools integrated | 1-2 | 8 | +300% |
| Pipeline steps | Manual | 7 automated | — |
| Cost per task | $0.05 (Claude) | $0.006 (hybrid) | -88% |

## Why It Matters

Multi-agent systems are the next evolution of AI-assisted development. The architecture that works is not complex message-passing middleware or elaborate orchestration frameworks — it's clear agent roles, independent quality auditing, and a filesystem-based communication protocol that any model can read. The hard part is not the technology. It's the discipline of giving each agent one job and trusting the system to coordinate.
