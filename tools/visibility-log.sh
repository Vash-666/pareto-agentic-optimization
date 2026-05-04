#!/bin/bash
# visibility-log.sh — System-wide Activity Log
# Tracks every pipeline run, audit, alert, and decision.
# Human-readable + machine-parseable. Git-friendly.
#
# Usage:
#   bash tools/visibility-log.sh log <type> <message> [metadata]
#   bash tools/visibility-log.sh recent [n]
#   bash tools/visibility-log.sh search <query>
#   bash tools/visibility-log.sh stats

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE="/Users/rohitvashist/.openclaw/workspace"
LOG_DIR="${WORKSPACE}/logs"
LOG_FILE="${LOG_DIR}/visibility.json"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$LOG_DIR"

# Init log file if not exists
if [[ ! -f "$LOG_FILE" ]]; then
    echo '{"entries":[],"version":"1.0","created":"'"$TIMESTAMP"'"}' > "$LOG_FILE"
fi

CMD="${1:-help}"

case "$CMD" in
    log)
        TYPE="${2:-}"
        MESSAGE="${3:-}"
        METADATA="${4:-{}}"
        
        if [[ -z "$TYPE" || -z "$MESSAGE" ]]; then
            echo "Usage: visibility-log.sh log <type> <message> [metadata]"
            echo "  Types: pipeline_run, audit, alert, gate_block, gate_pass,"
            echo "         decision, publish, error, milestone, report"
            exit 1
        fi
        
        ENTRY=$(jq -n \
            --arg ts "$TIMESTAMP" \
            --arg type "$TYPE" \
            --arg msg "$MESSAGE" \
            --arg meta "$METADATA" \
            '{timestamp: $ts, type: $type, message: $msg, metadata: ($meta | fromjson)}')
        
        jq --argjson entry "$ENTRY" '.entries += [$entry]' "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
        
        echo "✅ Logged: [$TYPE] $MESSAGE"
        ;;
    
    recent)
        N="${2:-10}"
        echo "═══════════════════════════════════════"
        echo "  RECENT ACTIVITY (last $N)"
        echo "═══════════════════════════════════════"
        jq -r --argjson n "$N" '.entries[-$n:] | reverse | .[] | 
            "  \(.timestamp[0:19]) | \(.type) | \(.message)"' "$LOG_FILE"
        echo ""
        echo "  Total entries: $(jq '.entries | length' "$LOG_FILE")"
        ;;
    
    search)
        QUERY="${2:-}"
        if [[ -z "$QUERY" ]]; then
            echo "Usage: visibility-log.sh search <query>"
            exit 1
        fi
        jq -r --arg q "$QUERY" '.entries[] | select(.message | test($q; "i")) | 
            "  \(.timestamp[0:19]) | \(.type) | \(.message)"' "$LOG_FILE"
        ;;
    
    stats)
        echo "═══════════════════════════════════════"
        echo "  VISIBILITY LOG STATS"
        echo "═══════════════════════════════════════"
        TOTAL=$(jq '.entries | length' "$LOG_FILE")
        echo "  Total entries: $TOTAL"
        echo ""
        echo "  By type:"
        jq -r '.entries | group_by(.type) | map({"type": .[0].type, "count": length}) | sort_by(-.count) | .[] | 
            "    \(.type): \(.count)"' "$LOG_FILE"
        echo ""
        echo "  First entry: $(jq -r '.entries[0].timestamp[0:19] // "N/A"' "$LOG_FILE")"
        echo "  Last entry:  $(jq -r '.entries[-1].timestamp[0:19] // "N/A"' "$LOG_FILE")"
        echo "  Log file:    ${LOG_FILE}"
        ;;
    
    export)
        FORMAT="${2:-markdown}"
        OUTPUT="${LOG_DIR}/visibility-log-$(date +%Y%m%d).md"
        
        echo "# Visibility Log — $(date +%Y-%m-%d)" > "$OUTPUT"
        echo "" >> "$OUTPUT"
        echo "| Time | Type | Message |" >> "$OUTPUT"
        echo "|------|------|---------|" >> "$OUTPUT"
        jq -r '.entries | reverse | .[:50] | .[] | 
            "| \(.timestamp[0:19]) | \(.type) | \(.message) |"' "$LOG_FILE" >> "$OUTPUT"
        echo ""
        echo "✅ Exported: $OUTPUT ($(wc -l < "$OUTPUT") lines)"
        ;;
    
    *)
        echo "Visibility Log — System Activity Tracker"
        echo ""
        echo "Usage:"
        echo "  log <type> <message> [json_metadata]   — Log an event"
        echo "  recent [n]                              — Show last n entries"
        echo "  search <query>                          — Search entries"
        echo "  stats                                   — Show statistics"
        echo "  export [format]                         — Export to markdown"
        echo ""
        echo "Examples:"
        echo "  visibility-log.sh log pipeline_run 'Pipeline MVP executed' '{\"tasks\":12,\"passed\":12}'"
        echo "  visibility-log.sh log audit 'Full system audit passed'"
        echo "  visibility-log.sh log gate_block 'QualityGate blocked P001-T3.2 at 2.5/10'"
        echo "  visibility-log.sh recent 5"
        ;;
esac