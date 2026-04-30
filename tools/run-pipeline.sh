#!/bin/bash
# run-pipeline.sh — Orchestrate all 5 Pareto phases end-to-end
# Usage: run-pipeline.sh [project] [milestone]
#   run-pipeline.sh all          — Run health check on every project
#   run-pipeline.sh pareto-optimization review 85  — Gate + batch + dashboard

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="${1:-all}"
MILESTONE="${2:-start}"
MIN_SCORE="${3:-}"

echo "══════════════════════════════════════════════"
echo "  🚀 PARETO PIPELINE — $(date)"
echo "══════════════════════════════════════════════"
echo ""

# Phase 1: Quality Gate
echo "─── Phase 1: Quality Gate ───"
if [[ "$PROJECT" == "all" ]]; then
    echo "  Skipping (use specific project for gates)"
else
    if [[ -n "$MIN_SCORE" ]]; then
        "${SCRIPT_DIR}/quality-gate.sh" "$PROJECT" "$MILESTONE" "$MIN_SCORE"
    else
        "${SCRIPT_DIR}/quality-gate.sh" "$PROJECT" "$MILESTONE"
    fi
    GATE_EXIT=$?
    if [[ $GATE_EXIT -ne 0 ]]; then
        echo ""
        echo "  ⛔ Pipeline halted at Phase 1 (gate blocked)"
        exit 1
    fi
fi
echo ""

# Phase 2: Batch Scan
echo "─── Phase 2: Batch Scan ───"
if [[ "$PROJECT" == "all" ]]; then
    "${SCRIPT_DIR}/batch-processor.sh" --all
else
    "${SCRIPT_DIR}/batch-processor.sh" "$PROJECT"
fi
echo ""

# Phase 3: Context Store Snapshot
echo "─── Phase 3: Context Snapshot ───"
"${SCRIPT_DIR}/context-store.sh" list
echo ""

# Phase 4: Router Classification
echo "─── Phase 4: Smart Route ───"
if [[ "$PROJECT" != "all" ]]; then
    python3 "${SCRIPT_DIR}/router-agent.py" "Run quality gates on ${PROJECT}" 2>/dev/null || echo "  Router unavailable"
fi
echo ""

# Phase 5: Auto Monitor
echo "─── Phase 5: Health Check ───"
"${SCRIPT_DIR}/auto-monitor.sh" check
echo ""

echo "══════════════════════════════════════════════"
echo "  ✅ PIPELINE COMPLETE — $(date)"
echo "══════════════════════════════════════════════"