#!/bin/bash
# Grade evaluation results against labels
# Usage: ./scripts/grade-evals.sh <results_dir>
# Example: ./scripts/grade-evals.sh eval/results/run_20260118_120000

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EVAL_DIR="$PROJECT_DIR/eval"
LABELS_DIR="$EVAL_DIR/labels"

if [[ -z "$1" ]]; then
    echo "Usage: ./scripts/grade-evals.sh <results_dir>"
    echo "Example: ./scripts/grade-evals.sh eval/results/run_20260118_120000"
    exit 1
fi

RESULTS_DIR="$1"

if [[ ! -d "$RESULTS_DIR" ]]; then
    echo "Error: Results directory not found: $RESULTS_DIR"
    exit 1
fi

echo "=== Grading Evaluation Results ==="
echo "Results: $RESULTS_DIR"
echo "Labels: $LABELS_DIR"
echo ""

# Summary stats
TOTAL_SCORE=0
TOTAL_POSSIBLE=0
CORRECT_CARDS=0
CORRECT_PLACEMENTS=0
CORRECT_ELIXIR=0
TOTAL_EVALS=0

printf "%-4s %-8s %-8s %-12s %-12s %-8s %s\n" "ID" "Score" "Elixir" "Card" "Placement" "Threats" "Notes"
printf "%-4s %-8s %-8s %-12s %-12s %-8s %s\n" "---" "-----" "------" "----" "---------" "-------" "-----"

for result_file in "$RESULTS_DIR"/*.json; do
    [[ -f "$result_file" ]] || continue

    ID=$(basename "$result_file" .json)
    LABEL_FILE="$LABELS_DIR/$ID.json"

    if [[ ! -f "$LABEL_FILE" ]]; then
        echo "[$ID] SKIP - No label file"
        continue
    fi

    TOTAL_EVALS=$((TOTAL_EVALS + 1))
    SCORE=0
    MAX_SCORE=85
    NOTES=""

    # Parse result and label
    RESULT_ELIXIR=$(jq -r '.perception.elixir // "null"' "$result_file" 2>/dev/null || echo "null")
    LABEL_ELIXIR=$(jq -r '.perception.elixir // "null"' "$LABEL_FILE" 2>/dev/null || echo "null")

    RESULT_CARD=$(jq -r '.decision.primary.card // .decision.primary.action // "null"' "$result_file" 2>/dev/null || echo "null")
    LABEL_CARD=$(jq -r '.decision.primary.card // .decision.primary.action // "null"' "$LABEL_FILE" 2>/dev/null || echo "null")

    RESULT_PLACEMENT=$(jq -r '.decision.primary.placement // "null"' "$result_file" 2>/dev/null || echo "null")
    LABEL_PLACEMENT=$(jq -r '.decision.primary.placement // "null"' "$LABEL_FILE" 2>/dev/null || echo "null")

    RESULT_THREATS=$(jq -r '.perception.threats | length' "$result_file" 2>/dev/null || echo "0")
    LABEL_THREATS=$(jq -r '.perception.threats | length' "$LABEL_FILE" 2>/dev/null || echo "0")

    # Score elixir (10 points)
    ELIXIR_STATUS="✗"
    if [[ "$RESULT_ELIXIR" != "null" && "$LABEL_ELIXIR" != "null" ]]; then
        DIFF=$((RESULT_ELIXIR - LABEL_ELIXIR))
        DIFF=${DIFF#-}  # Absolute value
        if [[ $DIFF -eq 0 ]]; then
            SCORE=$((SCORE + 10))
            ELIXIR_STATUS="✓"
            CORRECT_ELIXIR=$((CORRECT_ELIXIR + 1))
        elif [[ $DIFF -eq 1 ]]; then
            SCORE=$((SCORE + 7))
            ELIXIR_STATUS="~"
        elif [[ $DIFF -eq 2 ]]; then
            SCORE=$((SCORE + 4))
            ELIXIR_STATUS="~"
        fi
    fi

    # Score card choice (25 points)
    CARD_STATUS="✗"
    if [[ "$RESULT_CARD" == "$LABEL_CARD" ]]; then
        SCORE=$((SCORE + 25))
        CARD_STATUS="✓"
        CORRECT_CARDS=$((CORRECT_CARDS + 1))
    else
        # Check alternatives
        ALT_MATCH=$(jq -r --arg card "$RESULT_CARD" '.decision.alternatives[]? | select(.card == $card) | .validity' "$LABEL_FILE" 2>/dev/null || echo "")
        if [[ "$ALT_MATCH" == "optimal" ]]; then
            SCORE=$((SCORE + 20))
            CARD_STATUS="~opt"
        elif [[ "$ALT_MATCH" == "acceptable" ]]; then
            SCORE=$((SCORE + 15))
            CARD_STATUS="~acc"
        elif [[ "$ALT_MATCH" == "suboptimal" ]]; then
            SCORE=$((SCORE + 10))
            CARD_STATUS="~sub"
        fi
    fi

    # Score placement (20 points)
    PLACEMENT_STATUS="✗"
    if [[ "$RESULT_PLACEMENT" == "$LABEL_PLACEMENT" ]]; then
        SCORE=$((SCORE + 20))
        PLACEMENT_STATUS="✓"
        CORRECT_PLACEMENTS=$((CORRECT_PLACEMENTS + 1))
    elif [[ "$RESULT_PLACEMENT" != "null" && "$LABEL_PLACEMENT" != "null" ]]; then
        # Check same lane
        RESULT_COL=${RESULT_PLACEMENT:0:1}
        LABEL_COL=${LABEL_PLACEMENT:0:1}
        RESULT_LANE="left"
        LABEL_LANE="left"
        [[ $RESULT_COL -ge 5 ]] && RESULT_LANE="right"
        [[ $LABEL_COL -ge 5 ]] && LABEL_LANE="right"

        if [[ "$RESULT_LANE" == "$LABEL_LANE" ]]; then
            SCORE=$((SCORE + 15))
            PLACEMENT_STATUS="~lane"
        else
            SCORE=$((SCORE + 5))
            PLACEMENT_STATUS="~wrong"
        fi
    fi

    # Score threat detection (15 points) - simplified
    THREAT_STATUS="$RESULT_THREATS/$LABEL_THREATS"
    if [[ "$RESULT_THREATS" == "$LABEL_THREATS" ]]; then
        SCORE=$((SCORE + 15))
    elif [[ $RESULT_THREATS -gt 0 && $LABEL_THREATS -gt 0 ]]; then
        SCORE=$((SCORE + 8))
    fi

    # Add base points for hand recognition (10 points) and tower health (5 points)
    # Simplified: just add partial credit if perception exists
    if jq -e '.perception.hand' "$result_file" >/dev/null 2>&1; then
        SCORE=$((SCORE + 5))
    fi
    if jq -e '.perception.tower_health' "$result_file" >/dev/null 2>&1; then
        SCORE=$((SCORE + 3))
    fi

    # Reasoning points (15 points) - give partial credit if reasoning exists
    if jq -e '.decision.primary.reasoning' "$result_file" >/dev/null 2>&1; then
        REASONING=$(jq -r '.decision.primary.reasoning' "$result_file")
        if [[ ${#REASONING} -gt 20 ]]; then
            SCORE=$((SCORE + 7))
        fi
    fi

    TOTAL_SCORE=$((TOTAL_SCORE + SCORE))
    TOTAL_POSSIBLE=$((TOTAL_POSSIBLE + MAX_SCORE))

    printf "%-4s %-8s %-8s %-12s %-12s %-8s %s\n" "$ID" "$SCORE/85" "$ELIXIR_STATUS" "$CARD_STATUS" "$PLACEMENT_STATUS" "$THREAT_STATUS" "$NOTES"
done

echo ""
echo "=== Summary ==="
if [[ $TOTAL_EVALS -gt 0 ]]; then
    AVG=$((TOTAL_SCORE * 100 / TOTAL_POSSIBLE))
    echo "Total Score: $TOTAL_SCORE / $TOTAL_POSSIBLE ($AVG%)"
    echo "Correct Card: $CORRECT_CARDS / $TOTAL_EVALS"
    echo "Correct Placement: $CORRECT_PLACEMENTS / $TOTAL_EVALS"
    echo "Correct Elixir: $CORRECT_ELIXIR / $TOTAL_EVALS"
else
    echo "No evaluations graded."
fi

# Save summary
SUMMARY_FILE="$RESULTS_DIR/summary.json"
cat > "$SUMMARY_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "total_score": $TOTAL_SCORE,
  "total_possible": $TOTAL_POSSIBLE,
  "percentage": $AVG,
  "correct_cards": $CORRECT_CARDS,
  "correct_placements": $CORRECT_PLACEMENTS,
  "correct_elixir": $CORRECT_ELIXIR,
  "total_evals": $TOTAL_EVALS
}
EOF

echo ""
echo "Summary saved to: $SUMMARY_FILE"
