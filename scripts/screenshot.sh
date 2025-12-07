#!/bin/bash
# screenshot.sh - Capture BlueStacks window screenshot
# Usage: ./screenshot.sh [output_path]
# Returns: Path to saved screenshot

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_PATH="${1:-$PROJECT_DIR/screenshots/current.png}"
LOG_FILE="$PROJECT_DIR/logs/actions.log"

# Find BlueStacks window ID
# Try different possible app names for BlueStacks
get_window_id() {
    local window_id=""

    # Try BlueStacks App Player (common name)
    window_id=$(osascript -e 'tell application "System Events" to get id of first window of (first process whose name contains "BlueStacks")' 2>/dev/null || echo "")

    if [ -z "$window_id" ]; then
        # Try via window list
        window_id=$(osascript -e '
            tell application "System Events"
                set bluestacksProcess to first process whose name contains "BlueStacks"
                tell bluestacksProcess
                    set frontWindow to first window
                    return id of frontWindow
                end tell
            end tell
        ' 2>/dev/null || echo "")
    fi

    echo "$window_id"
}

# Alternative: capture by window name using screencapture -l flag
capture_bluestacks() {
    # BlueStacks has multiple windows - the game is in "BlueStacks Air", not the first window
    # Get bounds for the correct window (named "BlueStacks Air" or the larger window)
    local bounds=$(osascript -e '
        tell application "System Events"
            try
                set bluestacksProc to first application process whose name contains "BlueStacks"
                set allWins to every window of bluestacksProc
                -- Find the main game window (either by name or by size)
                repeat with w in allWins
                    set wName to name of w
                    set wSize to size of w
                    set wHeight to item 2 of wSize
                    -- The game window is "BlueStacks Air" or the window with height > 100
                    if wName is "BlueStacks Air" or wHeight > 100 then
                        set wPos to position of w
                        set x to item 1 of wPos
                        set y to item 2 of wPos
                        set w_ to item 1 of wSize
                        set h to item 2 of wSize
                        return "" & x & "," & y & "," & w_ & "," & h
                    end if
                end repeat
                return ""
            on error
                return ""
            end try
        end tell
    ' 2>/dev/null)

    if [ -n "$bounds" ] && [ "$bounds" != "" ]; then
        screencapture -R"$bounds" "$OUTPUT_PATH"
        if [ $? -eq 0 ] && [ -f "$OUTPUT_PATH" ]; then
            echo "$OUTPUT_PATH"
            return 0
        fi
    fi

    echo "ERROR: Could not find BlueStacks window. Is BlueStacks running?" >&2
    return 1
}

# Run capture
capture_bluestacks

# Log the screenshot with timestamp
echo "$(date '+%Y-%m-%d %H:%M:%S.%3N') SCREENSHOT" >> "$LOG_FILE"
