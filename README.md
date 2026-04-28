# ⚡ Pareto Agentic Optimization

A multi-agent system optimization framework with built-in **Quality Gates**, **Batch Processing**, **Shared Context Store**, **Smart Task Routing**, and **Automated Monitoring** — all running as lightweight shell scripts with zero external dependencies.

## Architecture Overview

The system is organized into 5 operational phases, each designed to work independently or as part of a coordinated pipeline:

```
┌──────────────────────────────────────────────────┐
│               PARETO AGENTIC SYSTEM              │
├──────────┬──────────┬──────────┬──────────┬──────┤
│ Quality  │  Batch   │ Context  │  Smart   │ Auto │
│  Gates   │Processor │  Store   │  Router  │Monitor│
│ Phase 1  │ Phase 2  │ Phase 3  │ Phase 4  │Phase5│
└──────────┴──────────┴──────────┴──────────┴──────┘
```

### Phase 1: Quality Gates (`tools/quality-gate.sh`)

Enforces minimum quality thresholds at project milestones:

| Milestone | Threshold | Description |
|-----------|-----------|-------------|
| `start`   | 60/100    | Initial project viability |
| `review`  | 75/100    | Peer review readiness |
| `complete`| 85/100    | Feature complete |
| `production` | 90/100 | Release ready |

```bash
./tools/quality-gate.sh <project-id> <milestone> [min-score]

# Example:
./tools/quality-gate.sh pareto-optimization review 85
# ✅ GATE PASSED (88 >= 85)
```

When a gate fails, it generates a blocker report with the score gap and required improvement areas.

### Phase 2: Batch Processor (`tools/batch-processor.sh`)

Parallel project health scanning using GNU Parallel. Processes up to 3 projects simultaneously and reports scores, status, and trends.

```bash
./tools/batch-processor.sh --all
# Scans all 4 projects in parallel with color-coded output
```

### Phase 3: Context Store (`tools/context-store.sh`)

Shared JSON-based state management with built-in history tracking. Every update archives the previous state for change auditing.

```bash
./tools/context-store.sh list                          # List all projects
./tools/context-store.sh get pareto-optimization       # Full project context
./tools/context-store.sh set pareto-optimization qualityScore 90  # Update score
./tools/context-store.sh history pareto-optimization   # Change history
```

### Phase 4: Smart Router (`tools/router-agent.py`)

Automatically classifies incoming tasks and routes them to the appropriate agent using keyword matching across 7 categories:

| Category | Routes To | Example |
|----------|-----------|---------|
| `quality` | QualityGuardian | "Check quality score" |
| `content` | Content Agent | "Write a README" |
| `product` | Product Manager | "Design roadmap" |
| `oversight` | Kiwi 2.6 | "Observe capability gaps" |
| `monitoring` | Switch | "Check system health" |

**Tested: 9/10 tasks auto-routed correctly.**

```bash
python3 tools/router-agent.py "Run quality gates on pipeline-mvp"
# → 🎯 Routes to: QualityGuardian (95% confidence)
```

### Phase 5: Auto Monitor + Dashboard (`tools/auto-monitor.sh`)

Continuous health monitoring with Telegram alerts on quality threshold breaches.

```bash
./tools/auto-monitor.sh check        # Single health scan
./tools/auto-monitor.sh cron         # Run + alert on dips below 75
./tools/auto-monitor.sh dashboard    # Generate live HTML dashboard
./tools/auto-monitor.sh log          # View recent checks
```

Generates a live HTML dashboard (`dashboard.html`) with:
- Quality averages across all projects
- Dashboard HTTP health status
- Per-project quality scores and status
- Color-coded health indicators

### Integrated Alerting

When average quality drops below 75, the cron monitor sends a Telegram alert. This runs automatically every 30 minutes for continuous oversight.

## Current Projects Managed

| Project | Quality | Status |
|---------|---------|--------|
| Pareto Optimization | 88/100 | 🚀 Active |
| Pipeline MVP | 92/100 | ✅ Complete |
| Kiwi Monitor | 85/100 | 🔧 Setup |
| Little Sprout Kitchen | 80/100 | 💡 Concept |

## Quick Start

```bash
# Prerequisites
brew install jq parallel fswatch

# Clone and run
git clone https://github.com/Vash-666/pareto-agentic-optimization.git
cd pareto-agentic-optimization

# Check system health
./tools/auto-monitor.sh check

# Run quality gate on a project
./tools/quality-gate.sh pipeline-mvp complete 85

# Scan all projects
./tools/batch-processor.sh --all

# Generate dashboard
./tools/auto-monitor.sh dashboard
open tools/dashboard.html
```

## Requirements

- **macOS** (bash 3.2+ compatible)
- **jq** — JSON processing (`brew install jq`)
- **GNU Parallel** — batch processing (`brew install parallel`)
- **fswatch** — file monitoring (`brew install fswatch`)
- **Python 3** — smart router
- **Telegram bot** (optional, for alerts)

## Philosophy

Built on three principles:
- **Zero external dependencies** — shell scripts, JSON files, git. No databases, no servers.
- **File-based state** — everything is a JSON file. Git-friendly, backup-friendly.
- **Fail loudly** — blocked gates generate explicit blocker reports. No silent failures.

## License

MIT
