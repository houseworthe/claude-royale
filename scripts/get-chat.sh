#!/bin/bash
# Get latest Twitch chat messages (only UNSEEN messages)
# Ensures the chat collector is running, then returns only new messages since last check

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHAT_LOG="$SCRIPT_DIR/chat-log.txt"
PID_FILE="$SCRIPT_DIR/.chat-collector.pid"
SEEN_FILE="$SCRIPT_DIR/.chat-last-seen"

# Check if collector is running
is_running() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            return 0
        fi
    fi
    return 1
}

# Start collector if not running
if ! is_running; then
    echo "[Starting chat collector...]" >&2
    cd "$SCRIPT_DIR"
    nohup node twitch-chat.js > /dev/null 2>&1 &
    echo $! > "$PID_FILE"
    sleep 2  # Give it time to connect
fi

# Output only NEW messages since last check
if [ -f "$CHAT_LOG" ]; then
    # Get total lines in chat log
    TOTAL_LINES=$(wc -l < "$CHAT_LOG" | tr -d ' ')

    # Get last seen line number (default 0 if file doesn't exist)
    if [ -f "$SEEN_FILE" ]; then
        LAST_SEEN=$(cat "$SEEN_FILE")
    else
        LAST_SEEN=0
    fi

    # Calculate new messages
    NEW_COUNT=$((TOTAL_LINES - LAST_SEEN))

    if [ "$NEW_COUNT" -gt 0 ]; then
        # Output only new messages
        tail -n "$NEW_COUNT" "$CHAT_LOG"
        # Update the seen marker
        echo "$TOTAL_LINES" > "$SEEN_FILE"
    else
        echo "[No new chat messages since last check]"
    fi
else
    echo "No chat messages yet. Collector just started - try again in a few seconds."
fi
