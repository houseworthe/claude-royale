#!/bin/bash

# Analyze agent action logs for debugging
# Usage: ./scripts/analyze_logs.sh [date]
# If no date provided, shows today's logs

DATE=${1:-$(date '+%Y-%m-%d')}
LOG_FILE="logs/agent-actions/$DATE.log"

if [ ! -f "$LOG_FILE" ]; then
  echo "No logs found for $DATE"
  exit 1
fi

echo "=== AGENT ACTION LOG ANALYSIS ==="
echo "Date: $DATE"
echo "=============================\n"

# Summary stats
echo "SUMMARY:"
echo "Total actions: $(wc -l < "$LOG_FILE")"
echo "Unique agents: $(cut -d'|' -f2 "$LOG_FILE" | sort | uniq | wc -l)"
echo "Unique action types: $(cut -d'|' -f3 "$LOG_FILE" | sort | uniq | wc -l)"
echo ""

# Actions by type
echo "ACTIONS BY TYPE:"
cut -d'|' -f3 "$LOG_FILE" | sed 's/^ //;s/ $//' | sort | uniq -c | sort -rn
echo ""

# Agent activity
echo "ACTIONS PER AGENT:"
cut -d'|' -f2 "$LOG_FILE" | sed 's/^ //;s/ $//' | sort | uniq -c | sort -rn
echo ""

# Card placements
echo "CARD PLACEMENTS:"
grep "CARD_PLAYED" "$LOG_FILE" | head -20
echo ""

# Decision reasoning
echo "DECISION REASONING (latest 10):"
grep "DECISION_REASONING" "$LOG_FILE" | tail -10
echo ""

# Lane detection
echo "LANE DETECTION:"
grep "LANE" "$LOG_FILE" | tail -10
