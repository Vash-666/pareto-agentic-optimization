# Automation Workflows — Topic Outline

**Status:** Outline
**Prerequisites:** Basic command line, Git fundamentals
**Related scripts:** `04-pipeline-orchestration.md`, `01-model-switching.md`

---

## 1. Pipeline Design

### Core Principles
- **Deterministic** — Same inputs always produce the same result
- **Gated** — Every phase has a quality threshold that blocks progression
- **Observable** — Every step is logged; every decision is inspectable
- **Safe to fail** — Failure at any phase produces a clear report, not a broken system

### The 5-Phase Pattern
1. **Quality Gate** — Check current score against milestone threshold
2. **Content Generation** — Execute agent tasks in dependency order
3. **Batch Processing** — Run parallel operations when possible
4. **Final Review** — Independent quality verification of all outputs
5. **Publication** — Git commit, push, tag

**Key insight:** The quality gate runs BEFORE content generation. This ensures the system only generates content if it can meet the quality bar.

---

## 2. Tool Orchestration

### The 7-Tool Stack

| Tool | Role | Trigger |
|---|---|---|
| `quality-gate.sh` | Score verification | Every phase transition |
| `context-store.sh` | State persistence | Read/write at every step |
| `batch-processor.sh` | Parallel execution | Content generation phase |
| `run-pipeline.sh` | Orchestrator | User command |
| `auto-publish.sh` | Git operations | Final phase |
| `visibility-log.sh` | Event logging | All phases |
| `generate-report.sh` | Summary | Post-publication |

### Orchestration Logic
```
run-pipeline.sh
  ├── phase 1: quality-gate.sh (start)
  ├── phase 2: context-store.sh (read) → agents → context-store.sh (write)
  ├── phase 3: batch-processor.sh (parallel execution)
  ├── phase 4: quality-gate.sh (complete) → generate-report.sh
  └── phase 5: auto-publish.sh (git + publish)
```

---

## 3. Git Integration

### Commit Structure
- Auto-generated commit messages follow a standard format:
  ```
  [project-id] milestone: summary message
  ```
- Example: `[teaching-portfolio] complete: 13 files, quality score 87/100`

### Branch Management
- Pipeline commits directly to `main` for this workflow (single-stream content)
- Tag format: `v<project>-<milestone>-<score>`
- Example: `vteaching-portfolio-complete-87`

### Safety Mechanisms
- `auto-publish.sh` checks for uncommitted changes before running
- Dry-run mode: `--dry-run` flag shows what would happen without executing
- Rollback: Each commit is tagged and reversible

---

## 4. Auto-Publishing

### Workflow
1. `git add` — Stage all changed files in the project directory
2. `git status` — Verify only expected files are staged
3. `git commit` — Structured commit message
4. `git push` — Push to configured remote
5. `git tag` — Tag with project ID, milestone, score

### Configuration
Auto-publish reads from context store:
```json
{
  "git.enabled": true,
  "git.remote": "origin",
  "git.branch": "main",
  "publish.dryRun": false,
  "publish.tagFormat": "v{project}-{milestone}-{score}"
}
```

### Failure Handling
- If `git push` fails (network, auth): Log the error, save pending changes, retry on next pipeline run
- If `git add` detects unexpected files: Halt with file list for review
- If commit conflicts: Halt and report conflict details

---

## 5. Monitoring & Alerts

### Visibility Log
Every pipeline event is recorded:
- Phase start/end times
- Score at each gate
- Tool execution results (pass/fail)
- File changes (added/modified/deleted)
- Failure points and error messages

### Alert Thresholds
- **Warning:** Score within 5 points of minimum threshold
- **Critical:** Gate blocked, pipeline halted, manual intervention required
- **Recovery:** Pipeline resumed after failure resolution

### Dashboard
A generated HTML dashboard (`dashboard.html`) shows:
- Quality score history (line chart)
- Pipeline run history
- Gate pass/fail rate
- Recent commits and tags

---

## 6. Common Issues

1. **Gate blocking repeatedly** — Check prompt quality first; it contributes 65% of the score
2. **Batch processor stalls** — Check for file locks or concurrent write conflicts
3. **Auto-publish fails** — Verify Git remote and authentication, run with `--dry-run` first
4. **Context store inconsistent** — Check that `context-store.sh` writes before agents read
5. **Visibility log missing** — Ensure `visibility-log.sh` is called at the start of each phase

---

## 7. Further Reading

- `04-pipeline-orchestration.md` — Full pipeline script and results
- `03-agent-architecture.md` — Agent roles in the pipeline
- `FOR-HUMANITY.md` — Why automation and quality control matter
