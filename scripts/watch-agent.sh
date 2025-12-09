#!/bin/bash
# watch-agent.sh - Watch real-time output for a specific agent (colorized)
# Usage: ./scripts/watch-agent.sh <agent_id>
# Example: ./scripts/watch-agent.sh A1

AGENT_ID="${1:-A1}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/logs/actions.log"

# Colors
WHITE='\033[1;37m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
MAGENTA='\033[1;35m'
RED='\033[1;31m'
BLUE='\033[1;34m'
RESET='\033[0m'

# Agent-specific color
case "$AGENT_ID" in
    A1) AGENT_COLOR="$RED" ;;
    A2) AGENT_COLOR="$GREEN" ;;
    A3) AGENT_COLOR="$BLUE" ;;
    *)  AGENT_COLOR="$WHITE" ;;
esac

# Create log file if it doesn't exist
mkdir -p "$PROJECT_DIR/logs"
touch "$LOG_FILE"

echo -e "${AGENT_COLOR}=== Agent $AGENT_ID Live Feed ===${RESET}"
echo ""

# Tail the log, filter for this agent, and colorize output
tail -f "$LOG_FILE" | grep --line-buffered "\[$AGENT_ID\]" | while read -r line; do
    # Parse the line: 2025-12-08 14:10:04 [A1] PLAY slot=1 cell=2F card=Giant reason="defending left lane push"

    # Extract components using sed
    timestamp=$(echo "$line" | sed -E 's/^([0-9-]+ [0-9:]+).*/\1/')
    slot=$(echo "$line" | sed -E 's/.*slot=([0-9]+).*/\1/')
    cell=$(echo "$line" | sed -E 's/.*cell=([A-Z0-9]+).*/\1/')
    card=$(echo "$line" | sed -E 's/.*card=([^ ]+).*/\1/')
    reason=$(echo "$line" | sed -E 's/.*reason="([^"]+)".*/\1/')

    # Check if reason was found (line might not have reason)
    if [[ "$line" != *"reason="* ]]; then
        reason=""
    fi

    # Print colorized output
    if [ -n "$reason" ]; then
        echo -e "${WHITE}${timestamp}${RESET} ${AGENT_COLOR}[$AGENT_ID]${RESET} ${WHITE}PLAY${RESET} slot=${CYAN}${slot}${RESET} cell=${YELLOW}${cell}${RESET} card=${GREEN}${card}${RESET} reason=\"${MAGENTA}${reason}${RESET}\""
    else
        echo -e "${WHITE}${timestamp}${RESET} ${AGENT_COLOR}[$AGENT_ID]${RESET} ${WHITE}PLAY${RESET} slot=${CYAN}${slot}${RESET} cell=${YELLOW}${cell}${RESET} card=${GREEN}${card}${RESET}"
    fi
done
