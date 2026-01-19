#!/bin/bash
# Aggregate multiple eval runs and calculate pass@k metrics
# Usage: ./scripts/aggregate-evals.sh <batch_dir>
# Example: ./scripts/aggregate-evals.sh eval/results/batch_20260118_120000

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EVAL_DIR="$PROJECT_DIR/eval"
LABELS_DIR="$EVAL_DIR/labels"

# Pass threshold (90%)
PASS_THRESHOLD=90

if [[ -z "$1" ]]; then
    echo "Usage: ./scripts/aggregate-evals.sh <batch_dir>"
    echo "Example: ./scripts/aggregate-evals.sh eval/results/batch_20260118_120000"
    exit 1
fi

BATCH_DIR="$1"

if [[ ! -d "$BATCH_DIR" ]]; then
    echo "Error: Batch directory not found: $BATCH_DIR"
    exit 1
fi

if [[ ! -f "$BATCH_DIR/batch.json" ]]; then
    echo "Error: batch.json not found in $BATCH_DIR"
    exit 1
fi

# Read batch metadata
K=$(jq -r '.k' "$BATCH_DIR/batch.json")
START=$(jq -r '.start' "$BATCH_DIR/batch.json")
END=$(jq -r '.end' "$BATCH_DIR/batch.json")

echo "=== Aggregating Evaluation Results ==="
echo "Batch: $BATCH_DIR"
echo "K (runs): $K"
echo "Screenshots: $START to $END"
echo "Pass threshold: $PASS_THRESHOLD%"
echo ""

# First, grade each run if not already graded
for run in $(seq 1 $K); do
    RUN_DIR="$BATCH_DIR/run_$run"
    if [[ -d "$RUN_DIR" && ! -f "$RUN_DIR/summary.json" ]]; then
        echo "Grading run_$run..."
        "$SCRIPT_DIR/grade-evals.sh" "$RUN_DIR" > /dev/null
    fi
done

# Collect per-screenshot data across all runs
declare -A SCREENSHOT_SCORES
declare -A SCREENSHOT_PASSES

echo ""
printf "%-4s %-12s %-8s %-10s %s\n" "ID" "Scores" "Passes" "Avg" "Status"
printf "%-4s %-12s %-8s %-10s %s\n" "---" "------" "------" "---" "------"

TOTAL_SCREENSHOTS=0
PASS_AT_K_COUNT=0
PASS_ALL_K_COUNT=0

# Process each screenshot
for i in $(seq $START $END); do
    LABEL_FILE="$LABELS_DIR/$i.json"
    if [[ ! -f "$LABEL_FILE" ]]; then
        continue
    fi

    TOTAL_SCREENSHOTS=$((TOTAL_SCREENSHOTS + 1))
    SCORES=""
    SCORE_SUM=0
    PASS_COUNT=0

    for run in $(seq 1 $K); do
        RESULT_FILE="$BATCH_DIR/run_$run/$i.json"
        SUMMARY_FILE="$BATCH_DIR/run_$run/summary.json"

        if [[ ! -f "$RESULT_FILE" ]]; then
            SCORES="${SCORES}-,"
            continue
        fi

        # Re-calculate score for this specific screenshot
        # (simplified - just use percentage of max)
        SCORE=$("$SCRIPT_DIR/grade-evals.sh" "$BATCH_DIR/run_$run" 2>/dev/null | grep "^$i " | awk -F'/' '{print $1}' | awk '{print $2}' || echo "0")

        # Extract just the number
        SCORE=$(echo "$SCORE" | tr -dc '0-9')
        if [[ -z "$SCORE" ]]; then
            SCORE=0
        fi

        SCORES="${SCORES}${SCORE},"
        SCORE_SUM=$((SCORE_SUM + SCORE))

        if [[ $SCORE -ge $PASS_THRESHOLD ]]; then
            PASS_COUNT=$((PASS_COUNT + 1))
        fi
    done

    # Remove trailing comma
    SCORES=${SCORES%,}

    # Calculate average
    if [[ $K -gt 0 ]]; then
        AVG=$((SCORE_SUM / K))
    else
        AVG=0
    fi

    # Determine status
    STATUS="FAIL"
    if [[ $PASS_COUNT -ge 1 ]]; then
        PASS_AT_K_COUNT=$((PASS_AT_K_COUNT + 1))
        STATUS="pass@k"
    fi
    if [[ $PASS_COUNT -eq $K ]]; then
        PASS_ALL_K_COUNT=$((PASS_ALL_K_COUNT + 1))
        STATUS="pass^k"
    fi

    printf "%-4s %-12s %-8s %-10s %s\n" "$i" "$SCORES" "$PASS_COUNT/$K" "$AVG%" "$STATUS"

    # Store for JSON output
    SCREENSHOT_SCORES[$i]="$SCORES"
    SCREENSHOT_PASSES[$i]=$PASS_COUNT
done

echo ""
echo "=== Summary ==="

# Calculate rates
if [[ $TOTAL_SCREENSHOTS -gt 0 ]]; then
    PASS_AT_K_RATE=$((PASS_AT_K_COUNT * 100 / TOTAL_SCREENSHOTS))
    PASS_ALL_K_RATE=$((PASS_ALL_K_COUNT * 100 / TOTAL_SCREENSHOTS))
else
    PASS_AT_K_RATE=0
    PASS_ALL_K_RATE=0
fi

echo "Total screenshots: $TOTAL_SCREENSHOTS"
echo "pass@$K (passed at least once): $PASS_AT_K_COUNT/$TOTAL_SCREENSHOTS ($PASS_AT_K_RATE%)"
echo "pass^$K (passed every time):   $PASS_ALL_K_COUNT/$TOTAL_SCREENSHOTS ($PASS_ALL_K_RATE%)"

# Save aggregate summary
AGGREGATE_FILE="$BATCH_DIR/aggregate.json"
cat > "$AGGREGATE_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "k": $K,
  "pass_threshold": $PASS_THRESHOLD,
  "total_screenshots": $TOTAL_SCREENSHOTS,
  "pass_at_k": {
    "count": $PASS_AT_K_COUNT,
    "rate": $PASS_AT_K_RATE
  },
  "pass_all_k": {
    "count": $PASS_ALL_K_COUNT,
    "rate": $PASS_ALL_K_RATE
  }
}
EOF

echo ""
echo "Aggregate saved to: $AGGREGATE_FILE"
