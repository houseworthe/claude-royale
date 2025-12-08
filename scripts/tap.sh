#!/bin/bash
# tap.sh - Tap a UI button
# Usage: ./tap.sh <button_name>
# Example: ./tap.sh battle
#
# Buttons are defined in config/coordinates.json under "buttons"
# Run ./scripts/calibrate.sh to set up coordinates

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_DIR/config/coordinates.json"

BUTTON="$1"

# Validate arguments
if [ -z "$BUTTON" ]; then
    echo "Usage: $0 <button_name>" >&2
    echo "Example: $0 battle" >&2
    echo "" >&2
    echo "Available buttons (from coordinates.json):" >&2
    # List all non-comment keys from buttons
    jq -r '.buttons | keys[] | select(startswith("_") | not)' "$CONFIG_FILE" 2>/dev/null | sed 's/^/  /' >&2
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: coordinates.json not found. Run calibrate.sh first." >&2
    exit 1
fi

# Get button coordinates - try multiple sections
BTN_X=$(jq -r ".buttons[\"$BUTTON\"][0]" "$CONFIG_FILE")
BTN_Y=$(jq -r ".buttons[\"$BUTTON\"][1]" "$CONFIG_FILE")

# If not found in buttons, try deck_slots
if [ "$BTN_X" == "null" ] || [ -z "$BTN_X" ]; then
    BTN_X=$(jq -r ".deck_slots[\"$BUTTON\"][0]" "$CONFIG_FILE")
    BTN_Y=$(jq -r ".deck_slots[\"$BUTTON\"][1]" "$CONFIG_FILE")
fi

# If not found in deck_slots, try upgrade_dialog
if [ "$BTN_X" == "null" ] || [ -z "$BTN_X" ]; then
    BTN_X=$(jq -r ".upgrade_dialog[\"$BUTTON\"][0]" "$CONFIG_FILE")
    BTN_Y=$(jq -r ".upgrade_dialog[\"$BUTTON\"][1]" "$CONFIG_FILE")
fi

# If not found in upgrade_dialog, try tower_troop
if [ "$BTN_X" == "null" ] || [ -z "$BTN_X" ]; then
    BTN_X=$(jq -r ".tower_troop[\"$BUTTON\"][0]" "$CONFIG_FILE")
    BTN_Y=$(jq -r ".tower_troop[\"$BUTTON\"][1]" "$CONFIG_FILE")
fi

# If not found in tower_troop, try towers
if [ "$BTN_X" == "null" ] || [ -z "$BTN_X" ]; then
    BTN_X=$(jq -r ".towers[\"$BUTTON\"][0]" "$CONFIG_FILE")
    BTN_Y=$(jq -r ".towers[\"$BUTTON\"][1]" "$CONFIG_FILE")
fi

# Handle result_ok alias for post_game_ok (CRITICAL: post-match button)
if [ "$BUTTON" == "result_ok" ]; then
    BUTTON="post_game_ok"
    BTN_X=$(jq -r ".buttons[\"post_game_ok\"][0]" "$CONFIG_FILE")
    BTN_Y=$(jq -r ".buttons[\"post_game_ok\"][1]" "$CONFIG_FILE")
fi

# If still not found and button is "post_game_ok", handle it
if [ "$BTN_X" == "null" ] || [ -z "$BTN_X" ]; then
    if [ "$BUTTON" == "post_game_ok" ]; then
        BTN_X=$(jq -r ".buttons[\"post_game_ok\"][0]" "$CONFIG_FILE")
        BTN_Y=$(jq -r ".buttons[\"post_game_ok\"][1]" "$CONFIG_FILE")
    fi
fi

if [ "$BTN_X" == "null" ] || [ -z "$BTN_X" ]; then
    echo "ERROR: Unknown button '$BUTTON'." >&2
    echo "Available buttons:" >&2
    jq -r '.buttons | keys[] | select(startswith("_") | not)' "$CONFIG_FILE" 2>/dev/null | sed 's/^/  /' >&2
    jq -r '.deck_slots | keys[] | select(startswith("_") | not)' "$CONFIG_FILE" 2>/dev/null | sed 's/^/  /' >&2
    jq -r '.upgrade_dialog | keys[] | select(startswith("_") | not)' "$CONFIG_FILE" 2>/dev/null | sed 's/^/  /' >&2
    jq -r '.tower_troop | keys[] | select(startswith("_") | not)' "$CONFIG_FILE" 2>/dev/null | sed 's/^/  /' >&2
    exit 1
fi

# Check if coordinates are calibrated (not [0,0])
if [ "$BTN_X" == "0" ] && [ "$BTN_Y" == "0" ]; then
    echo "WARNING: Button '$BUTTON' has not been calibrated (coordinates are 0,0)." >&2
    echo "Run ./scripts/calibrate.sh to set proper coordinates." >&2
fi

# Activate BlueStacks before clicking (required for clicks to register)
osascript -e 'tell application "BlueStacks" to activate' 2>/dev/null || true
sleep 0.1

# Execute click
cliclick "c:$BTN_X,$BTN_Y"

echo "Tapped $BUTTON at ($BTN_X, $BTN_Y)"

# Special handling for confirm_button - automatically tap dismiss after
if [ "$BUTTON" == "confirm_button" ]; then
    echo "Perfect. Now tap."
    sleep 0.5
    # Get the ok button coordinates and tap it
    OK_X=$(jq -r ".buttons[\"ok\"][0]" "$CONFIG_FILE")
    OK_Y=$(jq -r ".buttons[\"ok\"][1]" "$CONFIG_FILE")
    osascript -e 'tell application "BlueStacks" to activate' 2>/dev/null || true
    sleep 0.1
    cliclick "c:$OK_X,$OK_Y"
fi

# Special handling for tower_troop_confirm - automatically tap dismiss after
if [ "$BUTTON" == "tower_troop_confirm" ]; then
    echo "Perfect. Now tap."
    sleep 0.5
    # Get the ok button coordinates and tap it
    OK_X=$(jq -r ".buttons[\"ok\"][0]" "$CONFIG_FILE")
    OK_Y=$(jq -r ".buttons[\"ok\"][1]" "$CONFIG_FILE")
    osascript -e 'tell application "BlueStacks" to activate' 2>/dev/null || true
    sleep 0.1
    cliclick "c:$OK_X,$OK_Y"
fi

# Special handling for battle - wait 8s then play opening card from slot 1
if [ "$BUTTON" == "battle" ]; then
    echo "Waiting 8s for match to load..."
    sleep 8
    # Play opening card to LEFT side (2G)
    echo "Playing opening card (slot 1) to left side (2G)"
    "$SCRIPT_DIR/play_card.sh" 1 "2G"

    # Wait 3 seconds then play second card to RIGHT side (3G)
    sleep 3
    echo "Playing second card (slot 2) to right side (3G)"
    "$SCRIPT_DIR/play_card.sh" 2 "3G"
fi
