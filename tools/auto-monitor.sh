#!/bin/bash
# auto-monitor.sh — Automated system monitoring with alerting
# Runs periodic checks and alerts on quality drops
# Usage: auto-monitor.sh [--check] [--cron] [--dashboard]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTEXT_FILE="${SCRIPT_DIR}/context/projects.json"
LOG_DIR="${SCRIPT_DIR}/logs"
DASHBOARD_FILE="${SCRIPT_DIR}/dashboard.html"
mkdir -p "${LOG_DIR}"

# --- Heartbeat check (mirrors HEARTBEAT.md) ---
check_dashboard() {
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:18789/ 2>/dev/null || echo "000")
    echo "$code"
}

check_quality() {
    local overall=0
    local count=0
    while IFS=':' read -r project score; do
        score=$(echo "$score" | tr -d ' ')
        if [[ "$score" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            overall=$(echo "$overall + $score" | bc)
            count=$((count + 1))
        fi
    done < <(jq -r 'to_entries[] | "\(.key):\(.value.qualityScore)"' "$CONTEXT_FILE" 2>/dev/null)
    
    if [[ $count -gt 0 ]]; then
        echo "scale=1; $overall / $count" | bc
    else
        echo "0"
    fi
}

# --- Core check ---
run_check() {
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local dashboard_code
    dashboard_code=$(check_dashboard)
    local avg_quality
    avg_quality=$(check_quality)
    local qual_ok="YES"
    
    # Quality drop alert (if below 75)
    if (( $(echo "$avg_quality < 75" | bc -l) )); then
        qual_ok="ALERT"
    fi
    
    # Log the check
    cat >> "${LOG_DIR}/monitor.log" <<EOF
${timestamp} | Dash:${dashboard_code} | Qual:${avg_quality} | ${qual_ok}
EOF
    
    # Return summary
    echo "${timestamp}|${dashboard_code}|${avg_quality}|${qual_ok}"
}

# --- Generate HTML dashboard ---
generate_dashboard() {
    local rows=""
    local i=0
    
    while IFS=':' read -r project score status; do
        score=$(echo "$score" | tr -d ' ')
        status=$(echo "$status" | tr -d ' ')
        local color="green"
        if (( $(echo "$score < 75" | bc -l) )); then color="red"
        elif (( $(echo "$score < 85" | bc -l) )); then color="orange"
        fi
        
        i=$((i + 1))
        rows="${rows}<tr><td>${i}</td><td>${project}</td><td>${score}/100</td><td style=\"color:${color};font-weight:bold\">${status}</td></tr>\n"
    done < <(jq -r 'to_entries[] | "\(.key):\(.value.qualityScore):\(.value.status)"' "$CONTEXT_FILE" 2>/dev/null)
    
    cat > "$DASHBOARD_FILE" <<DASHHTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Pareto Agentic Dashboard</title>
<style>
body { font-family: -apple-system, sans-serif; background: #1a1a2e; color: #eee; margin: 40px; }
h1 { color: #e94560; font-size: 1.8em; }
.subtitle { color: #888; margin-bottom: 30px; }
.stats { display: flex; gap: 20px; margin-bottom: 30px; }
.card { background: #16213e; padding: 20px; border-radius: 10px; flex: 1; text-align: center; }
.card h2 { font-size: 2.5em; margin: 5px 0; }
.card p { color: #888; font-size: 0.9em; }
table { width: 100%; border-collapse: collapse; background: #16213e; border-radius: 10px; overflow: hidden; }
th { background: #0f3460; padding: 12px; text-align: left; }
td { padding: 10px 12px; border-top: 1px solid #1a1a2e; }
tr:hover { background: #0f3460; }
.footer { margin-top: 30px; color: #555; font-size: 0.8em; }
.alert { color: #e94560; font-weight: bold; }
.ok { color: #4ecca3; }
</style>
</head>
<body>
<h1>⚡ Pareto Agentic Dashboard</h1>
<p class="subtitle">Live project health — $(date -u +%Y-%m-%d\ %H:%M\ UTC)</p>
<div class="stats">
<div class="card"><p>Quality Avg</p><h2>$(check_quality)</h2></div>
<div class="card"><p>Dashboard</p><h2>$(check_dashboard)</h2></div>
<div class="card"><p>Projects</p><h2>$(jq -r 'keys | length' "$CONTEXT_FILE")</h2></div>
</div>
<table>
<tr><th>#</th><th>Project</th><th>Quality</th><th>Status</th></tr>
${rows}
</table>
<div class="footer">
Last check: $(date -u +%Y-%m-%dT%H:%M:%SZ) | Auto-monitor v1.0
</div>
</body>
</html>
DASHHTML
    
    echo "Dashboard: ${DASHBOARD_FILE}"
}

# --- Main ---
ACTION="${1:-check}"

case "$ACTION" in
    check|--check)
        run_check
        ;;
    cron|--cron)
        result=$(run_check)
        echo "$result" >> "${LOG_DIR}/cron-$(date +%Y%m%d).log"
        
        # Parse result
        IFS='|' read -r ts dash qual alert <<< "$result"
        
        if [[ "$alert" == "ALERT" ]]; then
            # Send Telegram alert
            local token="8795263736:AAGRBNkHexZh7OKVa2DH6uCORoL_ERAdaj0"
            local msg="🔴 QUALITY ALERT: Avg score ${qual} — below 75 threshold at $(date)"
            echo "$msg"
            curl -s "https://api.telegram.org/bot${token}/sendMessage" \
              -d "chat_id=7968379010" \
              -d "text=${msg}" >/dev/null 2>&1 || true
        fi
        ;;
    dashboard|--dashboard)
        generate_dashboard
        ;;
    log|--log)
        tail -20 "${LOG_DIR}/monitor.log" 2>/dev/null || echo "No log yet"
        ;;
    *)
        echo "Usage: auto-monitor.sh {check|cron|dashboard|log}"
        echo "  check     — Run single health check"
        echo "  cron      — Run check + alert on threshold breach"
        echo "  dashboard — Generate HTML dashboard"
        echo "  log       — Show recent checks"
        exit 1
        ;;
esac