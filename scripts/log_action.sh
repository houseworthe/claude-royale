#!/bin/bash

# Log player agent actions for debugging
# Usage: ./scripts/log_action.sh <agent_id> <action_type> <details>

AGENT_ID=$1
ACTION_TYPE=$2
DETAILS=$3

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S.%3N')
LOG_DIR="logs/agent-actions"
LOG_FILE="$LOG_DIR/$(date '+%Y-%m-%d').log"

# Create logs directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Log format: [TIMESTAMP] AGENT_ID | ACTION_TYPE | DETAILS
echo "[$TIMESTAMP] $AGENT_ID | $ACTION_TYPE | $DETAILS" >> "$LOG_FILE"

# Also output to stdout for immediate feedback during agent execution
echo "[$TIMESTAMP] $AGENT_ID | $ACTION_TYPE | $DETAILS"
