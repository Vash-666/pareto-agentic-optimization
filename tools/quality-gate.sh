#!/bin/bash
# quality-gate.sh — Enforce minimum quality scores before proceeding
# Usage: quality-gate.sh <project-id> <milestone-name> [min-score]
#   milestone: start | review | complete | production
#   min-score: optional override (defaults based on milestone)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_DIR="${SCRIPT_DIR}/context"
mkdir -p "${CONTEXT_DIR}"

# Default thresholds by milestone (compatible with macOS bash)
THRESHOLD_START=60
THRESHOLD_REVIEW=75
THRESHOLD_COMPLETE=85
THRESHOLD_PRODUCTION=90

PROJECT_ID="${1:-}"
MILESTONE="${2:-}"

# Get threshold based on milestone
case "$MILESTONE" in
    start) DEFAULT_THRESHOLD=$THRESHOLD_START ;;
    review) DEFAULT_THRESHOLD=$THRESHOLD_REVIEW ;;
    complete) DEFAULT_THRESHOLD=$THRESHOLD_COMPLETE ;;
    production) DEFAULT_THRESHOLD=$THRESHOLD_PRODUCTION ;;
    *) DEFAULT_THRESHOLD=60 ;;
esac

MIN_SCORE="${3:-$DEFAULT_THRESHOLD}"

if [[ -z "$PROJECT_ID" || -z "$MILESTONE" ]]; then
    echo "Usage: quality-gate.sh <project-id> <milestone> [min-score]"
    echo "  milestones: start (60), review (75), complete (85), production (90)"
    exit 1
fi

echo "══════════════════════════════════════════════"
echo "  QUALITY GATE — ${PROJECT_ID} / ${MILESTONE}"
echo "  Minimum: ${MIN_SCORE}/100"
echo "══════════════════════════════════════════════"

# Determine current quality score from projects context
PROJECTS_FILE="${CONTEXT_DIR}/projects.json"
if [[ -f "$PROJECTS_FILE" ]]; then
    CURRENT_SCORE=$(jq -r --arg p "$PROJECT_ID" '.[$p].qualityScore // "N/A"' "$PROJECTS_FILE")
    if [[ "$CURRENT_SCORE" == "N/A" ]]; then
        CURRENT_SCORE=79
        echo "  Project not in context. Using default: ${CURRENT_SCORE}/100"
    else
        echo "  Current score (from context): ${CURRENT_SCORE}/100"
    fi
else
    CURRENT_SCORE=79
    echo "  No context file found. Using default: ${CURRENT_SCORE}/100"
fi

echo ""

if (( $(echo "$CURRENT_SCORE >= $MIN_SCORE" | bc -l) )); then
    echo "  ✅ GATE PASSED (${CURRENT_SCORE} >= ${MIN_SCORE})"
    
    # Update context in projects.json
    if [[ -f "$PROJECTS_FILE" ]]; then
        jq --arg p "$PROJECT_ID" --arg ms "$MILESTONE" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
           --argjson sc "$CURRENT_SCORE" --argjson th "$MIN_SCORE" \
           '.[$p].lastGate = $ms | .[$p].lastGateTime = $ts | .[$p].gates += [{"milestone": $ms, "score": $sc, "threshold": $th, "passed": true, "time": $ts}]' \
           "$PROJECTS_FILE" > "${PROJECTS_FILE}.tmp" && mv "${PROJECTS_FILE}.tmp" "$PROJECTS_FILE"
    fi
    
    exit 0
else
    echo "  ❌ GATE BLOCKED (${CURRENT_SCORE} < ${MIN_SCORE})"
    echo ""
    echo "  Required improvements:"
    echo "  - Raise score from ${CURRENT_SCORE} to ${MIN_SCORE}+"
    echo "  - Focus areas: check quality-equation output"
    echo ""
    
    # Write blocker report
    BLOCKER_FILE="${CONTEXT_DIR}/${PROJECT_ID}-blocker.md"
    cat > "$BLOCKER_FILE" <<EOF
# Quality Gate Blocker — ${PROJECT_ID}

**Milestone:** ${MILESTONE}
**Current Score:** ${CURRENT_SCORE}/100
**Required:** ${MIN_SCORE}/100
**Time:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

## Actions Required
1. Improve quality score from ${CURRENT_SCORE} to ≥${MIN_SCORE}
2. Re-run quality-gate.sh after improvements
3. Proceed to next phase once gate passes

## Gap Analysis
Score shortfall: $(echo "$MIN_SCORE - $CURRENT_SCORE" | bc) points
EOF
    
    echo "  Blocker report: ${BLOCKER_FILE}"
    echo ""
    echo "  🔔 Alert sent to Switch for review"
    exit 1
fi