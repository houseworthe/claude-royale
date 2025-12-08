#!/bin/bash
# play_card.sh - Play a card from hand to a grid cell
# Usage: ./play_card.sh <slot 1-4> <grid_cell>
# Example: ./play_card.sh 2 3D (column 3, row D)
#
# Grid: 8 columns (1-4 Claude's half, 5-8 opponent's half) x 8 rows (A-H, bridge to king tower)
# Column 1-4: Claude's side (left to right)
# Column 5-8: Opponent's side (left to right)
# Row A-D: Bridge and midfield
# Row E-H: Deeper into the half

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
COORDS_FILE="$PROJECT_DIR/coordinates.json"
LOG_FILE="$PROJECT_DIR/logs/actions.log"

SLOT="$1"
CELL="$2"

# Validate arguments
if [ -z "$SLOT" ] || [ -z "$CELL" ]; then
    echo "Usage: $0 <slot 1-4> <grid_cell>" >&2
    echo "Example: $0 2 C3" >&2
    echo "" >&2
    echo "Grid cells (A-E rows, 1-5 columns):" >&2
    echo "  A1-A5 (top), B1-B5, C1-C5 (center), D1-D5, E1-E5 (bottom)" >&2
    exit 1
fi

if [ ! -f "$COORDS_FILE" ]; then
    echo "ERROR: coordinates.json not found." >&2
    exit 1
fi

# Get card slot coordinates
CARD_X=$(jq -r ".cards.slot_$SLOT[0]" "$COORDS_FILE")
CARD_Y=$(jq -r ".cards.slot_$SLOT[1]" "$COORDS_FILE")

if [ "$CARD_X" == "null" ] || [ -z "$CARD_X" ]; then
    echo "ERROR: Invalid slot '$SLOT'. Use 1-4." >&2
    exit 1
fi

# Get target coordinates - check grid cells first, then towers
TARGET_X=$(jq -r ".grid.cells[\"$CELL\"][0]" "$COORDS_FILE")
TARGET_Y=$(jq -r ".grid.cells[\"$CELL\"][1]" "$COORDS_FILE")

# If not found in grid, check towers section
if [ "$TARGET_X" == "null" ] || [ -z "$TARGET_X" ]; then
    TARGET_X=$(jq -r ".towers[\"$CELL\"][0]" "$COORDS_FILE")
    TARGET_Y=$(jq -r ".towers[\"$CELL\"][1]" "$COORDS_FILE")
fi

if [ "$TARGET_X" == "null" ] || [ -z "$TARGET_X" ]; then
    echo "ERROR: Invalid target '$CELL'." >&2
    echo "Valid grid cells: 1A-8A, 1B-8B, 1C-8C, 1D-8D, 1E-8E, 1F-8F, 1G-8G, 1H-8H" >&2
    echo "Valid towers: player_tower_left, player_tower_right, player_king_left, player_king_right," >&2
    echo "              enemy_tower_left, enemy_tower_right, enemy_king_left, enemy_king_right" >&2
    exit 1
fi

# Extract column number from cell (first digit)
COLUMN=${CELL:0:1}

# Card type validation (optional, warns if config exists)
CARD_TYPE=$(jq -r ".card_types.slot_$SLOT" "$COORDS_FILE" 2>/dev/null || echo "null")

if [ "$CARD_TYPE" != "null" ] && [ -n "$CARD_TYPE" ]; then
    if [ "$CARD_TYPE" == "troop" ] && [ "$COLUMN" -gt 4 ]; then
        echo "⚠️  WARNING: Attempting to place TROOP (slot $SLOT) in opponent's half (column $COLUMN)." >&2
        echo "   Troops can only be placed in columns 1-4 (your half)." >&2
        echo "   Exception: After destroying one of opponent's Crown Towers, columns 5-8 become available." >&2
        echo "" >&2
        # Continue anyway - don't block, just warn
    fi
fi

# Activate BlueStacks before clicking (required for clicks to register)
osascript -e 'tell application "BlueStacks" to activate' 2>/dev/null || true
sleep 0.1

# Execute: Click card, wait briefly, click target
# This two-click method is more reliable than drag-and-drop
cliclick "c:$CARD_X,$CARD_Y"
sleep 0.15
cliclick "c:$TARGET_X,$TARGET_Y"

# Log the action with timestamp
echo "$(date '+%Y-%m-%d %H:%M:%S.%3N') PLAY_CARD slot=$SLOT cell=$CELL" >> "$LOG_FILE"

echo "Played card $SLOT to $CELL ($TARGET_X, $TARGET_Y)"
