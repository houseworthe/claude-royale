#!/bin/bash
# analyze_board.sh - Use local Moondream vision model to describe game state
# Usage: ./analyze_board.sh [screenshot_path]
# Returns: Text description of game state for Haiku to process

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Ensure screenshots directory exists
mkdir -p "$PROJECT_DIR/screenshots"

# Take screenshot if no path provided
if [ -z "$1" ]; then
    SCREENSHOT_PATH="$PROJECT_DIR/screenshots/current.png"
    # Capture just the arena area (optimized region)
    BOUNDS="560,36,610,1078"
    screencapture -R"$BOUNDS" "$SCREENSHOT_PATH" 2>/dev/null
else
    SCREENSHOT_PATH="$1"
fi

# Check if screenshot exists
if [ ! -f "$SCREENSHOT_PATH" ]; then
    echo "ERROR: Screenshot not found at $SCREENSHOT_PATH" >&2
    exit 1
fi

# Check if Ollama is running (check API endpoint instead of process)
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "ERROR: Ollama not running. Start with: brew services start ollama" >&2
    exit 1
fi

# The prompt instructs Moondream to describe the game state in a structured way
# that includes our grid system (columns 1-8, rows A-H)
PROMPT="Describe this Clash Royale battle screenshot. Report:

SCREEN: [battle/menu/result/loading]
TIMER: [time remaining, e.g. 2:15 or overtime]
ELIXIR: [0-10, look at purple bar at bottom]

YOUR CARDS (4 slots at bottom, left to right):
- Slot 1: [card name]
- Slot 2: [card name]
- Slot 3: [card name]
- Slot 4: [card name]

BOARD STATE:
- Your troops: [list with approximate positions - left/center/right, near bridge/middle/back]
- Enemy troops: [list with positions]
- Tower health: [left tower %, right tower %, king tower %]

THREAT: [what's the biggest threat right now?]

Card names to look for: Giant (huge guy), Musketeer (red hair rifle), Valkyrie (pink hair axe), Archers (two women with bows), Bomber (yellow goggles), Minions (blue flying), Tombstone (gravestone), Arrows (red spell)

Be concise. Focus on positions and immediate threats."

# Call Moondream via Ollama API
# Using the REST API for better control over parameters
RESPONSE=$(curl -s http://localhost:11434/api/generate \
    -d "{
        \"model\": \"moondream\",
        \"prompt\": \"$PROMPT\",
        \"images\": [\"$(base64 -i "$SCREENSHOT_PATH")\"],
        \"stream\": false
    }" 2>/dev/null)

# Extract just the response text using Python (more reliable than grep for JSON)
echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('response','ERROR: No response'))"
