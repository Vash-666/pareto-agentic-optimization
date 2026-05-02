# Multi-Agent Systems — Topic Outline

**Status:** Outline
**Prerequisites:** Basic understanding of LLMs and APIs
**Related scripts:** `03-agent-architecture.md`, `04-pipeline-orchestration.md`

---

## 1. Why Multi-Agent?

- **The solo agent ceiling** — Single models have finite context windows, specialization limits, and quality blind spots
- **Cost optimization** — Using expensive models for all tasks is wasteful; routing to cheaper models saves 80%+ on operating costs
- **Independent quality assurance** — Autonomous systems cannot audit themselves reliably; a separate agent is required
- **Resilience** — One model failing should not stop the entire workflow

**Key insight:** Multi-agent systems are not about making agents smarter — they are about making the system more reliable.

---

## 2. Architecture Patterns

### Orchestrator Pattern
- Single coordinator routes tasks to specialized worker agents
- Pros: Simple, observable, easy to debug
- Cons: Central point of failure, orchestrator becomes bottleneck
- Best for: Teams starting with multi-agent systems

### Peer-to-Peer Pattern
- Agents communicate directly without central coordination
- Pros: No single point of failure, high parallelism
- Cons: Complex message routing, hard to debug
- Best for: Mature systems with stable agent contracts

### Pipeline Pattern
- Agents execute sequentially, each passing output to the next
- Pros: Clear dependency chain, simple state management
- Cons: Serial execution limits throughput
- Best for: Content generation pipelines with ordered steps

**Recommended:** Start with orchestrator, add peer-to-peer connections as needed.

---

## 3. Communication Protocols

### File-Based Communication
- Agents share state through structured files on the filesystem
- Advantages: Model-agnostic, always readable, no API dependencies
- File formats: Markdown for state, JSON for structured data, YAML for config
- Example: SESSION-CONTEXT.md shared across all agents

### API-Based Communication
- Agents expose endpoints for direct requests
- Advantages: Real-time, bidirectional, versionable
- Tradeoff: Requires HTTP infrastructure, adds latency

### Memory-Based Communication
- Shared vector store or database
- Advantages: Semantic retrieval, long-term persistence
- Tradeoff: Higher complexity, requires embedding infrastructure

**Recommended for AI systems:** File-based as primary, API for real-time coordination.

---

## 4. Quality Assurance

- **Independent auditing** — Quality agent should be a separate process from the content-producing agent
- **Deterministic scoring** — Use weighted equations, not subjective assessments
- **Gate thresholds** — Each milestone must pass a minimum score to proceed
- **Blocker reporting** — When a gate fails, produce a structured report of what needs fixing

**Anti-pattern:** Allowing the same agent to generate and review its own work. This defeats the purpose of quality control.

---

## 5. Real-World Examples

### Content Generation Pipeline
- 6 agents: Switch, QualityGuardian, Content, Grok, Product, Scaffolder
- Communication: File-based via SESSION-CONTEXT.md
- Quality: Deterministic scoring at every milestone
- Result: 39 files, 8 tools, 88% cost reduction

### Code Review System
- Agent 1: Linter integration
- Agent 2: Security analysis
- Agent 3: Performance review
- Quality: Combined scores from all three agents

### Customer Support System
- Agent 1: Intent classification (cheap model)
- Agent 2: Knowledge base retrieval
- Agent 3: Response generation (expensive model)
- Quality: Response must pass satisfaction scoring before sending

---

## 6. Common Pitfalls

1. **No independent quality check** — The generating agent should not be the reviewing agent
2. **Complex middleware** — File-based communication is simpler and more reliable than message queues
3. **Over-specialization** — Too many agents creates coordination overhead; start with 3-4
4. **Ignoring cost** — Every agent call has a cost; route simple tasks to cheap models
5. **No observability** — Every agent's decisions and outputs should be logged and inspectable

---

## 7. Further Reading

- `03-agent-architecture.md` — Full architecture documentation
- `04-pipeline-orchestration.md` — Pipeline execution details
- `resources/quality-equation-guide.md` — Quality scoring methodology
