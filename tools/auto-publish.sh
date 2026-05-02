#!/bin/bash
# auto-publish.sh — Pipeline Artifact Publisher
# Copies pipeline run outputs into the Pareto repo and pushes to GitHub.
#
# Usage:
#   ./auto-publish.sh pipeline-mvp          # Publish Pipeline MVP artifacts
#   ./auto-publish.sh pareto-optimization   # Publish Pareto run results
#   ./auto-publish.sh all                   # Publish all projects
#
# This is called automatically by run-pipeline.sh as the final step.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_DIR="/Users/rohitvashist/.openclaw/workspace/projects"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
COMMIT_MSG=""

publish_project() {
    local project_name="$1"
    local project_dir="$2"
    local artifact_dir="${SCRIPT_DIR}/../artifacts/${project_name}"

    echo "  Publishing: ${project_name}"

    # Check if the project directory has output/ or snapshots/
    local has_artifacts=false

    if [ -d "${project_dir}/output" ] && [ "$(ls -A "${project_dir}/output" 2>/dev/null)" ]; then
        has_artifacts=true
        mkdir -p "${artifact_dir}/${TIMESTAMP}"
        cp -r "${project_dir}/output/"* "${artifact_dir}/${TIMESTAMP}/"
        echo "    └─ output/ → artifacts/${project_name}/${TIMESTAMP}/ ($(ls "${project_dir}/output" | wc -l) files)"
    fi

    if [ -d "${project_dir}/snapshots" ] && [ "$(ls -A "${project_dir}/snapshots" 2>/dev/null)" ]; then
        has_artifacts=true
        mkdir -p "${artifact_dir}/${TIMESTAMP}"
        cp -r "${project_dir}/snapshots/"* "${artifact_dir}/${TIMESTAMP}/"
        echo "    └─ snapshots/ → artifacts/${project_name}/${TIMESTAMP}/"
    fi

    # Copy charter/readme if they exist
    for charter_file in "00-PROJECT-CHARTER.md" "01-TASK-BREAKDOWN.md" "02-AGENT-ASSIGNMENTS.md" "README.md" "PROJECT-SUMMARY.md"; do
        if [ -f "${project_dir}/${charter_file}" ]; then
            cp "${project_dir}/${charter_file}" "${artifact_dir}/${charter_file}" 2>/dev/null || true
        fi
    done

    if [ "$has_artifacts" = true ]; then
        COMMIT_MSG="${COMMIT_MSG}  - ${project_name}: ${TIMESTAMP}\n"
    else
        echo "    ⚠️  No artifacts found for ${project_name}"
    fi
}

echo "═══════════════════════════════════════"
echo "  AUTO-PUBLISH PIPELINE"
echo "  $(date)"
echo "═══════════════════════════════════════"

cd "${SCRIPT_DIR}/.."

# Determine which projects to publish
if [ "$1" = "all" ]; then
    echo "Publishing all projects..."
    publish_project "pipeline-mvp" "${PROJECTS_DIR}/Agentic AI Project Pipeline MVP-20260419-195408"
    publish_project "pareto-optimization" "${PROJECTS_DIR}/pareto-agentic-optimization"
    if [ -d "${PROJECTS_DIR}/kiwi-monitor" ]; then
        publish_project "kiwi-monitor" "${PROJECTS_DIR}/kiwi-monitor"
    fi
    publish_project "teaching-portfolio" "${PROJECTS_DIR}/teaching-portfolio"
else
    case "$1" in
        pipeline-mvp)
            publish_project "pipeline-mvp" "${PROJECTS_DIR}/Agentic AI Project Pipeline MVP-20260419-195408"
            ;;
        pareto-optimization)
            publish_project "pareto-optimization" "${PROJECTS_DIR}/pareto-agentic-optimization"
            ;;
        kiwi-monitor)
            publish_project "kiwi-monitor" "${PROJECTS_DIR}/kiwi-monitor"
            ;;
        teaching-portfolio)
            publish_project "teaching-portfolio" "${PROJECTS_DIR}/teaching-portfolio"
            ;;
        *)
            echo "Unknown project: $1"
            echo "Usage: $0 [pipeline-mvp|pareto-optimization|kiwi-monitor|teaching-portfolio|all]"
            exit 1
            ;;
    esac
fi

echo ""
echo "─── Commit & Push ───"

if [ -z "$(git status --porcelain)" ]; then
    echo "  Nothing to commit. All artifacts already pushed."
    exit 0
fi

git add artifacts/
git commit -m "Auto-publish pipeline artifacts [${TIMESTAMP}]

Artifacts published:
$(echo -e "$COMMIT_MSG")"
git push origin main 2>&1 || echo "  ⚠️  Push failed (SSH key issue?). Try manual push."

echo ""
echo "✅ Published to: https://github.com/Vash-666/pareto-agentic-optimization"
echo "═══════════════════════════════════════"
