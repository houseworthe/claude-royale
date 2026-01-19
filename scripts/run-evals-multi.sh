#!/bin/bash
# Run screenshot evaluations K times for pass@k consistency metrics
# Usage: ./scripts/run-evals-multi.sh [k] [start] [end]
# Examples:
#   ./scripts/run-evals-multi.sh           # Run all 25, 3 times (default)
#   ./scripts/run-evals-multi.sh 5         # Run all 25, 5 times
#   ./scripts/run-evals-multi.sh 3 1 10    # Run screenshots 1-10, 3 times

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
EVAL_DIR="$PROJECT_DIR/eval"
RESULTS_DIR="$EVAL_DIR/results"

# Parse arguments
K=${1:-3}
START=${2:-1}
END=${3:-25}

# Create a batch directory for this multi-run
BATCH_TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BATCH_DIR="$RESULTS_DIR/batch_$BATCH_TIMESTAMP"
mkdir -p "$BATCH_DIR"

echo "=== Multi-Run Evaluation (pass@k) ==="
echo "K (runs): $K"
echo "Screenshots: $START to $END"
echo "Batch dir: $BATCH_DIR"
echo ""

# Track run directories
RUN_DIRS=()

for run in $(seq 1 $K); do
    echo "--- Run $run of $K ---"

    # Run evals and capture output to find the run directory
    OUTPUT=$("$SCRIPT_DIR/run-evals.sh" "$START" "$END" 2>&1)

    # Extract the run directory from output (line: "Output: eval/results/run_TIMESTAMP")
    RUN_DIR=$(echo "$OUTPUT" | grep "Output:" | awk '{print $2}')

    if [[ -n "$RUN_DIR" && -d "$RUN_DIR" ]]; then
        # Move run into batch directory
        RUN_NAME=$(basename "$RUN_DIR")
        mv "$RUN_DIR" "$BATCH_DIR/run_$run"
        RUN_DIRS+=("$BATCH_DIR/run_$run")
        echo "Saved to: $BATCH_DIR/run_$run"
    else
        echo "WARNING: Could not find run directory for run $run"
    fi

    echo ""
done

# Save batch metadata
cat > "$BATCH_DIR/batch.json" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "k": $K,
  "start": $START,
  "end": $END,
  "runs": [
$(for i in $(seq 1 $K); do
    if [[ $i -gt 1 ]]; then echo ","; fi
    echo -n "    \"run_$i\""
done)
  ]
}
EOF

echo "=== Multi-Run Complete ==="
echo "Batch: $BATCH_DIR"
echo "Runs: $K"
echo ""
echo "Next step: Aggregate results with ./scripts/aggregate-evals.sh $BATCH_DIR"
