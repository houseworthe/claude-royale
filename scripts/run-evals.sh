#!/bin/bash
# Run screenshot evaluations using player-eval agent
# Usage: ./scripts/run-evals.sh [start] [end]
# Examples:
#   ./scripts/run-evals.sh          # Run all 25
#   ./scripts/run-evals.sh 1 5      # Run screenshots 1-5
#   ./scripts/run-evals.sh 10 10    # Run only screenshot 10

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EVAL_DIR="$PROJECT_DIR/eval"
RESULTS_DIR="$EVAL_DIR/results"
SCREENSHOTS_DIR="$EVAL_DIR/screenshots"

# Create results directory if needed
mkdir -p "$RESULTS_DIR"

# Parse arguments
START=${1:-1}
END=${2:-25}

# Timestamp for this run
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RUN_DIR="$RESULTS_DIR/run_$TIMESTAMP"
mkdir -p "$RUN_DIR"

echo "=== Screenshot Evaluation Run ==="
echo "Screenshots: $START to $END"
echo "Output: $RUN_DIR"
echo ""

# Track results
TOTAL=0
SUCCESS=0

for i in $(seq $START $END); do
    SCREENSHOT="$SCREENSHOTS_DIR/$i.png"
    OUTPUT="$RUN_DIR/$i.json"

    if [[ ! -f "$SCREENSHOT" ]]; then
        echo "[$i] SKIP - Screenshot not found"
        continue
    fi

    echo -n "[$i] Evaluating... "
    TOTAL=$((TOTAL + 1))

    # Run claude with player-eval agent
    # Using --print to get just the output, --dangerously-skip-permissions for non-interactive
    RESULT=$(claude -p "You are a Clash Royale screenshot evaluation agent. Read the screenshot at eval/screenshots/$i.png and output ONLY valid JSON with this structure:
{
  \"screen_type\": \"battle\" | \"home_menu\" | \"result\" | \"loading\",
  \"perception\": {
    \"elixir\": <1-10>,
    \"hand\": [<4 card names LEFT-to-RIGHT, or null for empty>],
    \"threats\": [{\"unit\": \"<name>\", \"lane\": \"left\"|\"right\", \"severity\": \"low\"|\"medium\"|\"high\"}],
    \"tower_health\": {\"left\": <number or \"full\">, \"right\": <>, \"king\": <>},
    \"enemy_tower_health\": {\"left\": <>, \"right\": <>}
  },
  \"decision\": {
    \"primary\": {
      \"card\": \"<card name or wait>\",
      \"slot\": <1-4 or null>,
      \"placement\": \"<grid like 3F or null>\",
      \"reasoning\": \"<why>\"
    }
  }
}
For non-battle screens, use action instead of card/slot/placement.
Card reference: Mini P.E.K.K.A(4), Bomber(2), Mega Minion(3), Tombstone(3), Archers(3), Giant(5), Valkyrie(4), Wizard(5)
Grid: Cols 1-4=left, 5-8=right. Rows F-G=defense. Enemy troops have RED icons.
Output ONLY JSON, no markdown, no explanation." --allowedTools "Read" 2>/dev/null)

    # Extract JSON from response using Python for robust handling
    JSON_RESULT=$(echo "$RESULT" | python3 -c '
import sys, json, re
text = sys.stdin.read()
text = re.sub(r"```json\s*", "", text)
text = re.sub(r"```", "", text)
depth = 0
start = -1
result = None
for i, c in enumerate(text):
    if c == "{":
        if depth == 0: start = i
        depth += 1
    elif c == "}":
        depth -= 1
        if depth == 0 and start >= 0:
            try:
                result = json.loads(text[start:i+1])
                break
            except: start = -1
if result: print(json.dumps(result))
else: print(text)
' 2>/dev/null)

    # Save result
    echo "$JSON_RESULT" > "$OUTPUT"

    # Validate JSON
    if jq empty "$OUTPUT" 2>/dev/null; then
        echo "OK"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "WARN - Invalid JSON"
    fi
done

echo ""
echo "=== Results ==="
echo "Completed: $SUCCESS/$TOTAL"
echo "Output dir: $RUN_DIR"
echo ""
echo "Next step: Run grading with ./scripts/grade-evals.sh $RUN_DIR"
