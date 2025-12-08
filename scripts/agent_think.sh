#!/bin/bash

# Capture agent thinking/debugging output to file
# This allows agents to log their decision-making during gameplay
# Usage: ./scripts/agent_think.sh <agent_num> <message>

AGENT_NUM=$1
shift
MESSAGE="$@"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')
LOG_DIR="logs/agent-thinking"
LOG_FILE="$LOG_DIR/$(date '+%Y-%m-%d').log"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log format: [TIMESTAMP] AGENT_<num> | <MESSAGE>
echo "[$TIMESTAMP] AGENT_$AGENT_NUM | $MESSAGE" >> "$LOG_FILE"
