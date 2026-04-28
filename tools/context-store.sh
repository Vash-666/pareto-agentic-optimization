#!/bin/bash
# context-store.sh — Shared context store for project state
# Usage: context-store.sh get <project-id> [field]
#        context-store.sh set <project-id> <field> <value>
#        context-store.sh list
#        context-store.sh history <project-id>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_FILE="${SCRIPT_DIR}/context/projects.json"
HISTORY_DIR="${SCRIPT_DIR}/context/history"
mkdir -p "${HISTORY_DIR}"

ACTION="${1:-}"
PROJECT="${2:-}"

case "$ACTION" in
    get)
        if [[ -z "$PROJECT" ]]; then
            echo "Usage: context-store.sh get <project-id> [field]"
            exit 1
        fi
        FIELD="${3:-}"
        if [[ -n "$FIELD" ]]; then
            jq -r ".[\"$PROJECT\"].$FIELD // \"not found\"" "$CONTEXT_FILE"
        else
            jq ".[\"$PROJECT\"] // {error: \"project not found\"}" "$CONTEXT_FILE"
        fi
        ;;
    
    set)
        if [[ -z "${3:-}" || -z "${4:-}" ]]; then
            echo "Usage: context-store.sh set <project-id> <field> <value>"
            exit 1
        fi
        FIELD="$3"
        VALUE="$4"
        
        # Archive current state before updating
        cp "$CONTEXT_FILE" "${HISTORY_DIR}/$(date +%Y%m%d-%H%M%S)-${PROJECT}.json"
        
        # Update field
        jq --arg p "$PROJECT" --arg f "$FIELD" --arg v "$VALUE" \
           '.[$p] = (.[$p] // {}) | .[$p][$f] = $v | .[$p].lastUpdated = (now | todate)' \
           "$CONTEXT_FILE" > "${CONTEXT_FILE}.tmp" && mv "${CONTEXT_FILE}.tmp" "$CONTEXT_FILE"
        echo "✅ ${PROJECT}.${FIELD} = ${VALUE}"
        ;;
    
    list)
        jq -r 'keys[] as $k | "\($k): \(.[$k].status // "unknown") — \(.[$k].qualityScore // "?")/100"' "$CONTEXT_FILE"
        ;;
    
    history)
        if [[ -z "$PROJECT" ]]; then
            echo "Usage: context-store.sh history <project-id>"
            exit 1
        fi
        ls -t "${HISTORY_DIR}/"*"${PROJECT}.json" 2>/dev/null | head -5 || echo "No history for ${PROJECT}"
        ;;
    
    *)
        echo "Usage: context-store.sh {get|set|list|history} [args...]"
        echo ""
        echo "Commands:"
        echo "  get <project> [field]     — Get project context or specific field"
        echo "  set <project> <field> <val> — Update a field"
        echo "  list                      — List all projects"
        echo "  history <project>         — Show recent changes"
        exit 1
        ;;
esac