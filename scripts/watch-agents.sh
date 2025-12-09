#!/bin/bash
# watch-agents.sh - Watch real-time output for ALL agents (color-coded)
# Usage: ./scripts/watch-agents.sh

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

# Create log file if it doesn't exist
mkdir -p "$PROJECT_DIR/logs"
touch "$LOG_FILE"

echo -e "${WHITE}=== All Agents Live Feed ===${RESET}"
echo -e "${RED}A1${RESET} | ${GREEN}A2${RESET} | ${BLUE}A3${RESET}"
echo ""

# Tail the log and colorize output for all agents
tail -f "$LOG_FILE" | while read -r line; do
    # Skip lines without agent tags
    if [[ "$line" != *"[A"*"]"* ]]; then
        continue
    fi

    # Extract agent ID
    agent_id=$(echo "$line" | sed -E 's/.*\[(A[0-9]+)\].*/\1/')

    # Set agent color
    case "$agent_id" in
        A1) AGENT_COLOR="$RED" ;;
        A2) AGENT_COLOR="$GREEN" ;;
        A3) AGENT_COLOR="$BLUE" ;;
        *)  AGENT_COLOR="$WHITE" ;;
    esac

    # Extract components using sed
    timestamp=$(echo "$line" | sed -E 's/^([0-9-]+ [0-9:]+).*/\1/')
    slot=$(echo "$line" | sed -E 's/.*slot=([0-9]+).*/\1/')
    cell=$(echo "$line" | sed -E 's/.*cell=([A-Z0-9]+).*/\1/')
    card=$(echo "$line" | sed -E 's/.*card=([^ ]+).*/\1/')
    reason=$(echo "$line" | sed -E 's/.*reason="([^"]+)".*/\1/')

    # Check if reason was found
    if [[ "$line" != *"reason="* ]]; then
        reason=""
    fi

    # Print colorized output
    if [ -n "$reason" ]; then
        echo -e "${WHITE}${timestamp}${RESET} ${AGENT_COLOR}[$agent_id]${RESET} ${WHITE}PLAY${RESET} slot=${CYAN}${slot}${RESET} cell=${YELLOW}${cell}${RESET} card=${GREEN}${card}${RESET} reason=\"${MAGENTA}${reason}${RESET}\""
    else
        echo -e "${WHITE}${timestamp}${RESET} ${AGENT_COLOR}[$agent_id]${RESET} ${WHITE}PLAY${RESET} slot=${CYAN}${slot}${RESET} cell=${YELLOW}${cell}${RESET} card=${GREEN}${card}${RESET}"
    fi
done
