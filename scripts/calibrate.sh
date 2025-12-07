#!/bin/bash
# calibrate.sh - Interactive coordinate calibration tool
# Usage: ./calibrate.sh [section]
# Sections: all, cards, arena, menu, dialogs, shop, chests
# Click on locations when prompted, coordinates are saved to config/coordinates.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_DIR/config/coordinates.json"
SECTION="${1:-all}"

echo "=== Clash Royale Coordinate Calibration ==="
echo ""
echo "This tool will help you map coordinates for the game."
echo "Make sure BlueStacks is open with Clash Royale."
echo ""
echo "For each prompt, position your mouse over the indicated location"
echo "and press ENTER to record the coordinates."
echo ""

# Get current mouse position
get_mouse_pos() {
    cliclick p | tr ',' ' '
}

# Prompt user and record position
record_position() {
    local name="$1"
    local description="$2"

    echo "---"
    echo "Position: $name"
    echo "  -> $description"
    echo ""
    read -p "Move mouse to position and press ENTER... "

    local pos=$(get_mouse_pos)
    local x=$(echo "$pos" | awk '{print $1}')
    local y=$(echo "$pos" | awk '{print $2}')

    echo "  Recorded: ($x, $y)"
    echo ""

    # Return as space-separated values
    echo "$x $y"
}

# Initialize arrays to store values
declare -A recorded

# Helper to get x from recorded
get_x() {
    echo "$1" | awk '{print $1}'
}

get_y() {
    echo "$1" | awk '{print $2}'
}

echo "Section: $SECTION"
echo "Press ENTER to begin calibration..."
read

# ========== CARD SLOTS (in battle) ==========
if [ "$SECTION" == "all" ] || [ "$SECTION" == "cards" ]; then
    echo ""
    echo "=== CARD SLOTS (in a battle) ==="
    echo "These are the 4 card positions in your hand"
    echo "(You need to be in a battle or training match)"
    echo ""

    recorded[card1]=$(record_position "card_slot_1" "CENTER of your leftmost card")
    recorded[card2]=$(record_position "card_slot_2" "CENTER of your second card from left")
    recorded[card3]=$(record_position "card_slot_3" "CENTER of your third card from left")
    recorded[card4]=$(record_position "card_slot_4" "CENTER of your rightmost card")
fi

# ========== ARENA POSITIONS ==========
if [ "$SECTION" == "all" ] || [ "$SECTION" == "arena" ]; then
    echo ""
    echo "=== ARENA POSITIONS ==="
    echo "Key positions where you'll place troops (in battle)"
    echo ""

    recorded[bridge_left]=$(record_position "bridge_left" "Left bridge (where troops cross)")
    recorded[bridge_right]=$(record_position "bridge_right" "Right bridge (where troops cross)")
    recorded[center]=$(record_position "center" "Center of YOUR side of the arena")
    recorded[left_lane]=$(record_position "left_lane" "Middle of left lane (your side)")
    recorded[right_lane]=$(record_position "right_lane" "Middle of right lane (your side)")
    recorded[behind_king]=$(record_position "behind_king" "Behind your King tower")
    recorded[enemy_left]=$(record_position "enemy_left_princess" "Near enemy's left Princess tower")
    recorded[enemy_right]=$(record_position "enemy_right_princess" "Near enemy's right Princess tower")
fi

# ========== ELIXIR BAR ==========
if [ "$SECTION" == "all" ] || [ "$SECTION" == "arena" ]; then
    echo ""
    echo "=== ELIXIR BAR ==="
    echo ""

    recorded[elixir_start]=$(record_position "elixir_start" "LEFT edge of elixir bar")
    recorded[elixir_end]=$(record_position "elixir_end" "RIGHT edge of elixir bar (when full)")
fi

# ========== MAIN MENU BUTTONS ==========
if [ "$SECTION" == "all" ] || [ "$SECTION" == "menu" ]; then
    echo ""
    echo "=== MAIN MENU BUTTONS ==="
    echo "(Exit battle if needed to see the main menu)"
    echo ""
    read -p "Press ENTER when on the main menu..."

    recorded[battle]=$(record_position "battle" "The BATTLE button")
    recorded[shop]=$(record_position "shop" "Shop button (bottom bar)")
    recorded[cards]=$(record_position "cards" "Cards button (bottom bar)")
    recorded[clan]=$(record_position "clan" "Clan/Social button (bottom bar)")
    recorded[events]=$(record_position "events" "Events/Activity button (bottom bar)")
fi

# ========== CHEST SLOTS ==========
if [ "$SECTION" == "all" ] || [ "$SECTION" == "chests" ]; then
    echo ""
    echo "=== CHEST SLOTS ==="
    echo "The 4 chest slots on the main menu (left to right)"
    echo ""

    recorded[chest_1]=$(record_position "chest_1" "First chest slot (leftmost)")
    recorded[chest_2]=$(record_position "chest_2" "Second chest slot")
    recorded[chest_3]=$(record_position "chest_3" "Third chest slot")
    recorded[chest_4]=$(record_position "chest_4" "Fourth chest slot (rightmost)")
fi

# ========== DIALOG BUTTONS ==========
if [ "$SECTION" == "all" ] || [ "$SECTION" == "dialogs" ]; then
    echo ""
    echo "=== COMMON DIALOG BUTTONS ==="
    echo "These appear in various screens/dialogs"
    echo ""

    recorded[ok]=$(record_position "ok" "OK/Continue button (post-match, dialogs)")
    recorded[cancel]=$(record_position "cancel" "Cancel/Close button (X or Cancel)")
    recorded[back]=$(record_position "back" "Back arrow (top left usually)")
fi

# ========== ACTION BUTTONS ==========
if [ "$SECTION" == "all" ] || [ "$SECTION" == "dialogs" ]; then
    echo ""
    echo "=== ACTION BUTTONS ==="
    echo "Skip any that aren't visible right now (press ENTER with mouse anywhere)"
    echo ""

    recorded[upgrade]=$(record_position "upgrade" "Upgrade button (on card info screen)")
    recorded[open_chest]=$(record_position "open_chest" "Open button (when viewing a chest)")
    recorded[buy]=$(record_position "buy" "Buy button (in shop)")
    recorded[request]=$(record_position "request" "Request button (clan card request)")
    recorded[rematch]=$(record_position "rematch" "Play Again/Rematch (post-match)")
fi

# ========== SHOP ELEMENTS ==========
if [ "$SECTION" == "all" ] || [ "$SECTION" == "shop" ]; then
    echo ""
    echo "=== SHOP ELEMENTS ==="
    echo "(Open the shop first)"
    echo ""
    read -p "Press ENTER when in the shop..."

    recorded[free_item]=$(record_position "free_item" "Free item location (if visible)")
    recorded[shop_tab_1]=$(record_position "shop_tab_1" "First shop tab")
    recorded[shop_tab_2]=$(record_position "shop_tab_2" "Second shop tab")
    recorded[shop_tab_3]=$(record_position "shop_tab_3" "Third shop tab")
fi

# ========== BUILD JSON ==========
echo ""
echo "=== SAVING COORDINATES ==="

# Read existing config or use defaults
if [ -f "$CONFIG_FILE" ]; then
    existing=$(cat "$CONFIG_FILE")
else
    existing='{}'
fi

# Build new JSON (merging with existing for partial calibrations)
cat > "$CONFIG_FILE" << EOF
{
  "_comment": "Calibrated coordinates. Run ./scripts/calibrate.sh to update.",
  "_last_calibrated": "$(date -Iseconds)",

  "card_slots": {
    "1": [${recorded[card1]:-$(echo "$existing" | jq -r '.card_slots["1"] | @csv' | tr -d '"' | tr ',' ' ') 0 0}],
    "2": [${recorded[card2]:-$(echo "$existing" | jq -r '.card_slots["2"] | @csv' | tr -d '"' | tr ',' ' ') 0 0}],
    "3": [${recorded[card3]:-$(echo "$existing" | jq -r '.card_slots["3"] | @csv' | tr -d '"' | tr ',' ' ') 0 0}],
    "4": [${recorded[card4]:-$(echo "$existing" | jq -r '.card_slots["4"] | @csv' | tr -d '"' | tr ',' ' ') 0 0}]
  },

  "arena": {
    "bridge_left": [${recorded[bridge_left]:-0 0}],
    "bridge_right": [${recorded[bridge_right]:-0 0}],
    "center": [${recorded[center]:-0 0}],
    "left_lane": [${recorded[left_lane]:-0 0}],
    "right_lane": [${recorded[right_lane]:-0 0}],
    "behind_king": [${recorded[behind_king]:-0 0}],
    "enemy_left_princess": [${recorded[enemy_left]:-0 0}],
    "enemy_right_princess": [${recorded[enemy_right]:-0 0}]
  },

  "buttons": {
    "battle": [${recorded[battle]:-0 0}],
    "shop": [${recorded[shop]:-0 0}],
    "cards": [${recorded[cards]:-0 0}],
    "clan": [${recorded[clan]:-0 0}],
    "events": [${recorded[events]:-0 0}],

    "chest_1": [${recorded[chest_1]:-0 0}],
    "chest_2": [${recorded[chest_2]:-0 0}],
    "chest_3": [${recorded[chest_3]:-0 0}],
    "chest_4": [${recorded[chest_4]:-0 0}],

    "ok": [${recorded[ok]:-0 0}],
    "cancel": [${recorded[cancel]:-0 0}],
    "back": [${recorded[back]:-0 0}],

    "upgrade": [${recorded[upgrade]:-0 0}],
    "open_chest": [${recorded[open_chest]:-0 0}],
    "buy": [${recorded[buy]:-0 0}],
    "request": [${recorded[request]:-0 0}],
    "rematch": [${recorded[rematch]:-0 0}],

    "free_item": [${recorded[free_item]:-0 0}],
    "shop_tab_1": [${recorded[shop_tab_1]:-0 0}],
    "shop_tab_2": [${recorded[shop_tab_2]:-0 0}],
    "shop_tab_3": [${recorded[shop_tab_3]:-0 0}]
  },

  "elixir_bar": {
    "start": [${recorded[elixir_start]:-0 0}],
    "end": [${recorded[elixir_end]:-0 0}]
  }
}
EOF

# Fix the JSON formatting (replace spaces with commas in arrays)
sed -i '' 's/\[\([0-9]*\) \([0-9]*\)\]/[\1, \2]/g' "$CONFIG_FILE"

echo ""
echo "=== CALIBRATION COMPLETE ==="
echo "Coordinates saved to: $CONFIG_FILE"
echo ""
echo "You can run partial calibrations with:"
echo "  ./calibrate.sh cards    - Just card slots"
echo "  ./calibrate.sh arena    - Arena positions + elixir"
echo "  ./calibrate.sh menu     - Main menu buttons"
echo "  ./calibrate.sh chests   - Chest slots"
echo "  ./calibrate.sh dialogs  - Dialog/action buttons"
echo "  ./calibrate.sh shop     - Shop elements"
echo ""
cat "$CONFIG_FILE"
