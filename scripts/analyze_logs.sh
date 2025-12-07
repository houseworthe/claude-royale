#!/bin/bash
# analyze_logs.sh - Analyze action logs from a battle
# Usage: ./analyze_logs.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/logs/actions.log"

if [ ! -f "$LOG_FILE" ]; then
    echo "No log file found at $LOG_FILE"
    exit 1
fi

echo "=== Battle Action Analysis ==="
echo ""

# Count actions
SCREENSHOTS=$(grep -c "SCREENSHOT" "$LOG_FILE" 2>/dev/null || echo "0")
CARD_PLAYS=$(grep -c "PLAY_CARD" "$LOG_FILE" 2>/dev/null || echo "0")

echo "Total screenshots: $SCREENSHOTS"
echo "Total card plays: $CARD_PLAYS"
echo ""

# Get time range
FIRST_ACTION=$(head -1 "$LOG_FILE" | cut -d' ' -f1,2)
LAST_ACTION=$(tail -1 "$LOG_FILE" | cut -d' ' -f1,2)
echo "First action: $FIRST_ACTION"
echo "Last action: $LAST_ACTION"
echo ""

# Calculate time between card plays
echo "=== Card Play Timing ==="
grep "PLAY_CARD" "$LOG_FILE" | while read line; do
    echo "$line"
done
echo ""

# Calculate average time between screenshots
echo "=== Screenshot Frequency ==="
PREV_TIME=""
grep "SCREENSHOT" "$LOG_FILE" | head -10 | while read line; do
    CURR_TIME=$(echo "$line" | cut -d' ' -f2)
    if [ -n "$PREV_TIME" ]; then
        echo "Screenshot at $CURR_TIME"
    fi
    PREV_TIME=$CURR_TIME
done

echo ""
echo "=== Raw Log (last 20 lines) ==="
tail -20 "$LOG_FILE"
