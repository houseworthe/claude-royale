#!/bin/bash
# calibrate-button.sh - Calibrate a single button coordinate
# Usage: ./calibrate-button.sh <button_name>
# Example: ./calibrate-button.sh 2v2_accept
#
# Updates just one button in coordinates.local.json without touching other values

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_DIR/config/coordinates.local.json"

BUTTON="$1"

if [ -z "$BUTTON" ]; then
    echo "Usage: $0 <button_name>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0 2v2_accept    - Calibrate 2v2 accept button" >&2
    echo "  $0 battle        - Calibrate battle button" >&2
    echo "  $0 ok            - Calibrate OK button" >&2
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: $CONFIG_FILE not found." >&2
    echo "Copy coordinates.json to coordinates.local.json first." >&2
    exit 1
fi

echo "=== Single Button Calibration ==="
echo ""
echo "Button: $BUTTON"
echo ""

# Check current value
CURRENT_X=$(jq -r ".buttons[\"$BUTTON\"][0] // \"not found\"" "$CONFIG_FILE")
CURRENT_Y=$(jq -r ".buttons[\"$BUTTON\"][1] // \"not found\"" "$CONFIG_FILE")

if [ "$CURRENT_X" == "not found" ]; then
    echo "Note: '$BUTTON' doesn't exist yet, it will be added."
else
    echo "Current coordinates: ($CURRENT_X, $CURRENT_Y)"
fi

echo ""
echo "Position your mouse over the $BUTTON button and press ENTER..."
read

# Get mouse position
POS=$(cliclick p)
X=$(echo "$POS" | cut -d',' -f1)
Y=$(echo "$POS" | cut -d',' -f2)

echo "Recorded: ($X, $Y)"
echo ""

# Update the JSON file
jq ".buttons[\"$BUTTON\"] = [$X, $Y]" "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"

echo "Updated $CONFIG_FILE"
echo ""
echo "Test with: ./scripts/tap.sh $BUTTON"
