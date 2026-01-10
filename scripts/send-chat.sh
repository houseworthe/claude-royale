#!/bin/bash
# Send a message to Twitch chat
# Usage: ./scripts/send-chat.sh "Your message here"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(grep -v '^#' "$PROJECT_DIR/.env" | xargs)
fi

MESSAGE="$1"

if [ -z "$MESSAGE" ]; then
    echo "Usage: send-chat.sh \"message\""
    exit 1
fi

node "$PROJECT_DIR/twitch-chat.js" --send "$MESSAGE"
