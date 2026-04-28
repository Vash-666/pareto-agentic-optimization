#!/bin/bash
# batch-processor.sh — Process multiple projects in single pass using GNU Parallel
# Usage: batch-processor.sh [--all | project1 project2 ...]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_FILE="${SCRIPT_DIR}/context/projects.json"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_DIR="${SCRIPT_DIR}/reports"
mkdir -p "${REPORT_DIR}"

echo "══════════════════════════════════════════════"
echo "  BATCH PROCESSOR — $(date)"
echo "══════════════════════════════════════════════"

# Get list of projects
if [[ "${1:-}" == "--all" || $# -eq 0 ]]; then
    PROJECTS=$(jq -r 'keys[]' "$CONTEXT_FILE")
else
    PROJECTS="$@"
fi

PROJECT_COUNT=$(echo "$PROJECTS" | wc -l | tr -d ' ')
echo "  Projects: ${PROJECT_COUNT}"
echo ""

# Process each project in parallel (up to 3 at once)
process_project() {
    local project=$1
    local ctx="/Users/rohitvashist/.openclaw/workspace/projects/pareto-agentic-optimization/tools/context/projects.json"
    local score=$(jq -r --arg p "$project" '.[$p].qualityScore // "N/A"' "$ctx")
    local status=$(jq -r --arg p "$project" '.[$p].status // "unknown"' "$ctx")
    echo "  📊 ${project}: ${score}/100 (${status})"
}
export -f process_project

echo "$PROJECTS" | parallel -j 3 process_project {}

echo ""
echo "══════════════════════════════════════════════"
echo "  Batch Complete: $(date)"
echo "══════════════════════════════════════════════"