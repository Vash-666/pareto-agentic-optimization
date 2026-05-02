# Architecture

**System:** Pareto Agentic Optimization — Teaching Portfolio Module
**Agents:** 6 | **Tools:** 8 | **Pipeline Phases:** 5 | **Quality Gates:** 4

---

## Agent Architecture

```
                    ┌─────────────────────────────────────────────┐
                    │             SWITCH (Orchestrator)            │
                    │        Model: Claude Sonnet                 │
                    │  Role: Route tasks, maintain state file     │
                    └──────────┬──────┬──────┬──────┬────────────┘
                               │      │      │      │
          ┌────────────────────┘      │      │      └────────────────────┐
          │                           │      │                           │
          ▼                           ▼      ▼                           ▼
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   QUALITYGUARDIAN│  │    CONTENT       │  │      GROK        │  │     PRODUCT       │
│   Model: DeepSeek│  │ Model: Claude    │  │ Model: Perplexity│  │ Model: DeepSeek   │
│   Role: Auditor  │  │ Role: Writer     │  │ Role: Research   │  │ Role: PM          │
│   Independent QA │  │ Scripts & guides │  │ Fact validation  │  │ Task definition   │
└──────┬───────────┘  └─────────┬────────┘  └────────┬─────────┘  └──────────────────┘
       │                        │                     │
       └────────────────────────┼─────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │     SCAFFOLDER       │
                    │   Model: DeepSeek    │
                    │   Role: Infra        │
                    │   Files, dirs, tools │
                    │   Pipeline execution │
                    └──────────────────────┘
```

### Agent Descriptions

| Agent | Model | Responsibility | Gate Role |
|---|---|---|---|
| Switch | Claude Sonnet | Orchestrate tasks, maintain SESSION-CONTEXT.md | Final audit (production) |
| QualityGuardian | DeepSeek | Independent scoring, gate enforcement | All gates |
| Content | Claude Sonnet | Generate scripts, guides, documentation | Content creation |
| Grok | Perplexity/Grok | Research, fact validation, references | Research quality |
| Product | DeepSeek | Task definition, priorities, scope | Phase planning |
| Scaffolder | DeepSeek | File ops, pipeline execution, tools | Infrastructure |

---

## Tool Interconnections

```
                    ┌─────────────────────────────────────┐
                    │          RUN-PIPELINE.SH            │
                    │         (Orchestrator)              │
                    └──────┬───────┬───────┬───────┬─────┘
                           │       │       │       │
           ┌───────────────┘       │       │       └───────────────┐
           │                       │       │                       │
           ▼                       ▼       ▼                       ▼
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  QUALITY-GATE.SH │   │ CONTEXT-STORE.SH │   │ BATCH-PROC.SH   │   │  AUTO-PUBLISH.SH │
│  Score check     │   │  Read/write ctx  │   │  Parallel ops    │   │  Git + publish   │
│  Gate enforcement│   │  State mgmt      │   │  Concurrent jobs │   │  Commit + tag    │
└──────────────────┘   └──────────────────┘   └──────────────────┘   └──────────────────┘
         │                     │                      │                       │
         └─────────────────────┼──────────────────────┘                       │
                               │                                              │
                               ▼                                              ▼
                    ┌──────────────────┐                           ┌──────────────────┐
                    │ VISIBILITY-LOG   │                           │ GENERATE-REPORT  │
                    │ Event tracking   │                           │ Summary & stats  │
                    │ Blockers & alerts│                           │ Dashboard output │
                    └──────────────────┘                           └──────────────────┘
```

### Tool Roles

| Tool | Input | Output | Phase |
|---|---|---|---|
| `quality-gate.sh` | Project ID, milestone, min score | Pass/fail, blocker report | Start, Complete |
| `context-store.sh` | Key-value pairs | Updated context file | All phases |
| `batch-processor.sh` | Task list | Parallel execution results | Content generation |
| `run-pipeline.sh` | Project ID, milestone, score | Orchestration commands | All phases |
| `auto-publish.sh` | Project directory | Git commit, push, tag | Publication |
| `visibility-log.sh` | Event data | Log entry | All phases |
| `generate-report.sh` | Pipeline results | Summary report | Post-publication |

---

## Pipeline Phases

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          PIPELINE FLOW                                  │
│                                                                         │
│  ┌─────────┐   ┌──────────┐   ┌──────────┐   ┌─────────┐   ┌────────┐ │
│  │ Phase 1 │──▶│ Phase 2  │──▶│ Phase 3  │──▶│ Phase 4 │──▶│ Phase 5│ │
│  │ QUALITY │   │ CONTENT  │   │  BATCH   │   │  FINAL  │   │PUBLISH │ │
│  │  GATE   │   │ GENERATE │   │ PROCESS  │   │ REVIEW  │   │        │ │
│  └─────────┘   └──────────┘   └──────────┘   └─────────┘   └────────┘ │
│       │              │              │              │              │     │
│       ▼              ▼              ▼              ▼              ▼     │
│   Score ≥ 60    Agent tasks     Parallel ops    Score ≥ 85    Git push │
│   to proceed    in order        with limits     or block      + tag    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Quality Gates

Each milestone enforces a deterministic quality score:

```
START ────── Gate: 60/100 ────── REVIEW ────── Gate: 75/100 ────── COMPLETE ────── Gate: 85/100 ────── PRODUCTION
  │                                  │                                  │                                  │
  ▼                                  ▼                                  ▼                                  ▼
Structure             Content accuracy           Independent verification          Enterprise audit
All files present     Readable, recruiter-ready  All metrics documented            Stress-tested
```

### Gate Enforcement Flow

```
1. Agent generates output
2. Output written to filesystem (read-only for QualityGuardian)
3. QualityGuardian reads output independently
4. QualityGuardian computes score via Quality Equation
5. Score compared against milestone threshold
6. If score >= threshold: ✅ Gate passed → proceed
7. If score < threshold: ❌ Gate blocked → blocker report → fix → re-run
```

---

## Independent Verification Circuit

QualityGuardian operates as an independent auditor. It cannot be influenced by the producing agent.

```
┌────────────────┐         ┌──────────────────┐         ┌────────────────┐
│ Producing Agent │  writes │    Filesystem     │  reads  │  QualityGuardian│
│ (Content/Grok)  │────────▶│   (read-only)    │◀────────│  (Independent)  │
└────────────────┘         └──────────────────┘         └────────────────┘
                                                               │
                                                               ▼
                                                      ┌────────────────┐
                                                      │  Quality Score  │
                                                      │  (Deterministic)│
                                                      └────────────────┘
                                                               │
                                                               ▼
                                                    ┌──────────────────────┐
                                                    │  Gate Decision:      │
                                                    │  Pass / Block + Fix  │
                                                    └──────────────────────┘
```

This circuit guarantees that:
- No agent can inflate its own quality score
- QualityGuardian has no dependency on the producing agent's runtime state
- The score is reproducible by any independent observer
- Gate failures produce actionable blocker reports

---

## State Flow

```
SESSION-CONTEXT.md (Shared State File)
         │
         ├── Written by: Switch (phase transitions), any agent (task completion)
         ├── Read by: All agents (on activation)
         │
         ├── Contains:
         │   ├── Current phase
         │   ├── Files created/modified
         │   ├── Decisions and rationale
         │   ├── Pending actions
         │   └── Quality scores
         │
         └── Survives: Model switches, agent restarts, session timeouts
```

---

## Scaling

Adding a new agent requires:
1. Define its role and model
2. Set its quality gate threshold
3. Register it in Switch's routing table
4. Give it read/write access to SESSION-CONTEXT.md

The architecture scales without changes to communication protocols or tool integrations. The bottleneck is agent role clarity, not system complexity.
