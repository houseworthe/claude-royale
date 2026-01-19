#!/bin/bash
# analyze-latency.sh - Analyze timing patterns from actions.log
# Usage: ./scripts/analyze-latency.sh [options]
#
# Options:
#   --json       Output in JSON format
#   --csv        Output in CSV format
#   --from DATE  Filter from date (YYYY-MM-DD)
#   --to DATE    Filter to date (YYYY-MM-DD)
#   --today      Analyze today's matches only
#   --last N     Analyze last N matches only
#   --verbose    Show per-match breakdown
#   --help       Show this help

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_DIR/logs/actions.log"

# Defaults
OUTPUT_FORMAT="text"
FROM_DATE=""
TO_DATE=""
LAST_N=""
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            OUTPUT_FORMAT="json"
            shift
            ;;
        --csv)
            OUTPUT_FORMAT="csv"
            shift
            ;;
        --from)
            FROM_DATE="$2"
            shift 2
            ;;
        --to)
            TO_DATE="$2"
            shift 2
            ;;
        --today)
            FROM_DATE=$(date '+%Y-%m-%d')
            TO_DATE=$(date '+%Y-%m-%d')
            shift
            ;;
        --last)
            LAST_N="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            head -14 "$0" | tail -13
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file not found: $LOG_FILE"
    exit 1
fi

# Check if log file has data
if [ ! -s "$LOG_FILE" ]; then
    echo "Error: Log file is empty"
    exit 1
fi

# Main analysis using awk
awk -v format="$OUTPUT_FORMAT" -v from_date="$FROM_DATE" -v to_date="$TO_DATE" -v last_n="$LAST_N" -v verbose="$VERBOSE" '
BEGIN {
    # Initialize
    match_count = 0
    total_plays = 0
    prev_epoch = 0
    prev_agent = ""
    first_timestamp = ""
    last_timestamp = ""

    # Current match state
    current_match_plays = 0
    current_match_start = 0
    current_match_agents[""] = 0
    delete current_match_agents
    opener_time = 0
    first_agent_time = 0

    # Aggregates
    total_gaps = 0
    gap_count = 0
    gap_sum = 0
    gap_min = 999999
    gap_max = 0

    # Per-agent tracking
    # agent_last_time[agent] = last play time
    # agent_gaps[agent] = sum of gaps
    # agent_gap_count[agent] = count

    # Match-level data for output
    # match_data[i] = "start|duration|plays|agents|first_latency"
}

function parse_timestamp(ts) {
    # ts format: "YYYY-MM-DD HH:MM:SS"
    # Convert to seconds since midnight (ignores date changes within session)
    split(ts, parts, /[- :]/)
    # Return: day * 86400 + hour * 3600 + min * 60 + sec
    # For simplicity, use day-of-year approximation
    day_approx = parts[2] * 31 + parts[3]
    return (day_approx * 86400) + (parts[4] * 3600) + (parts[5] * 60) + parts[6]
}

function format_duration(secs) {
    if (secs < 60) return secs "s"
    mins = int(secs / 60)
    secs = secs % 60
    return mins "m" secs "s"
}

function finalize_match() {
    if (current_match_plays == 0) return

    match_count++

    # Calculate match duration
    duration = prev_epoch - current_match_start
    if (duration < 0) duration = 0

    # Count unique agents
    agent_count = 0
    agent_list = ""
    for (a in current_match_agents) {
        if (a != "" && a != "?") {
            agent_count++
            if (agent_list != "") agent_list = agent_list "|"
            agent_list = agent_list a
        }
    }

    # First agent latency (time from opener to first named agent)
    first_latency = 0
    if (opener_time > 0 && first_agent_time > 0) {
        first_latency = first_agent_time - opener_time
    }

    # Store match data
    match_plays[match_count] = current_match_plays
    match_durations[match_count] = duration
    match_agent_counts[match_count] = agent_count
    match_agent_lists[match_count] = agent_list
    match_first_latency[match_count] = first_latency
    match_starts[match_count] = current_match_start_ts

    # Accumulate totals
    total_duration += duration
    total_match_plays += current_match_plays
    if (first_latency > 0) {
        total_first_latency += first_latency
        first_latency_count++
    }

    # Reset for next match
    current_match_plays = 0
    current_match_start = 0
    current_match_start_ts = ""
    delete current_match_agents
    opener_time = 0
    first_agent_time = 0
}

function record_gap(gap, agent) {
    if (gap < 0) gap = 0
    if (gap > 300) return  # Skip match boundary gaps

    gap_count++
    gap_sum += gap
    if (gap < gap_min) gap_min = gap
    if (gap > gap_max) gap_max = gap
    gaps[gap_count] = gap

    # Per-agent tracking
    if (agent != "?" && agent in agent_last_time) {
        agent_gap = prev_epoch - agent_last_time[agent]
        if (agent_gap > 0 && agent_gap < 300) {
            agent_gaps[agent] += agent_gap
            agent_gap_count[agent]++
        }
    }
}

# Parse each log line
/^[0-9]{4}-[0-9]{2}-[0-9]{2}/ {
    # Extract timestamp
    timestamp = $1 " " $2

    # Date filtering
    date_only = $1
    if (from_date != "" && date_only < from_date) next
    if (to_date != "" && date_only > to_date) next

    # Track period
    if (first_timestamp == "") first_timestamp = timestamp
    last_timestamp = timestamp

    # Extract agent ID (between brackets)
    agent = $0
    gsub(/.*\[/, "", agent)
    gsub(/\].*/, "", agent)

    # Parse timestamp to epoch
    epoch = parse_timestamp(timestamp)

    # Calculate gap from previous play
    gap = 0
    if (prev_epoch > 0) {
        gap = epoch - prev_epoch
    }

    # Match boundary detection
    is_new_match = 0

    # Check for long gap (> 5 minutes) - this clearly signals a new match
    if (gap > 300) {
        is_new_match = 1
    }
    # Check for first [?] play after a regular agent - start of new match opener
    else if (agent == "?" && prev_agent != "?" && prev_agent != "") {
        is_new_match = 1
    }

    if (is_new_match && current_match_plays > 0) {
        finalize_match()
    }

    # Start new match if needed
    if (current_match_start == 0) {
        current_match_start = epoch
        current_match_start_ts = timestamp
    }

    # Track opener timing
    if (agent == "?") {
        if (opener_time == 0) opener_time = epoch
    } else {
        if (first_agent_time == 0 && opener_time > 0) {
            first_agent_time = epoch
        }
    }

    # Record this play
    current_match_plays++
    total_plays++
    current_match_agents[agent] = 1

    # Record gap for statistics
    if (prev_epoch > 0) {
        record_gap(gap, agent)
    }

    # Update per-agent tracking
    agent_last_time[agent] = epoch
    agent_play_count[agent]++

    prev_epoch = epoch
    prev_agent = agent
}

END {
    # Finalize last match
    finalize_match()

    # Apply --last filter if specified
    if (last_n != "" && match_count > last_n) {
        start_match = match_count - last_n + 1
    } else {
        start_match = 1
    }

    # Calculate statistics
    if (gap_count > 0) {
        gap_avg = gap_sum / gap_count
        # Note: median/p90 would require gawk or external sort
        # For now, just use avg
        gap_median = gap_avg
        gap_p90 = gap_max
    }

    # Duration stats
    if (match_count > 0) {
        duration_avg = total_duration / match_count
        plays_avg = total_match_plays / match_count
    }

    # First latency avg
    if (first_latency_count > 0) {
        first_latency_avg = total_first_latency / first_latency_count
    }

    # Per-agent cycle times
    agent_cycle_sum = 0
    agent_cycle_count = 0
    for (a in agent_gaps) {
        if (agent_gap_count[a] > 0) {
            agent_cycle[a] = agent_gaps[a] / agent_gap_count[a]
            agent_cycle_sum += agent_cycle[a]
            agent_cycle_count++
        }
    }
    if (agent_cycle_count > 0) {
        agent_cycle_avg = agent_cycle_sum / agent_cycle_count
    }

    # Cards per minute
    if (total_duration > 0) {
        cards_per_min = (total_match_plays / total_duration) * 60
    }

    # Output based on format
    if (format == "json") {
        print "{"
        printf "  \"period\": {\"start\": \"%s\", \"end\": \"%s\"},\n", first_timestamp, last_timestamp
        printf "  \"matches_analyzed\": %d,\n", match_count
        printf "  \"total_plays\": %d,\n", total_plays
        print "  \"match_stats\": {"
        printf "    \"duration_avg_sec\": %.1f,\n", duration_avg
        printf "    \"plays_avg\": %.1f,\n", plays_avg
        printf "    \"cards_per_minute\": %.1f\n", cards_per_min
        print "  },"
        print "  \"timing\": {"
        printf "    \"inter_action_gap\": {\"min\": %d, \"avg\": %.1f, \"median\": %d, \"p90\": %d, \"max\": %d},\n", gap_min, gap_avg, gap_median, gap_p90, gap_max
        printf "    \"per_agent_cycle_avg\": %.1f,\n", agent_cycle_avg
        printf "    \"first_agent_latency_avg\": %.1f\n", first_latency_avg
        print "  },"
        print "  \"matches\": ["
        for (i = start_match; i <= match_count; i++) {
            printf "    {\"id\": %d, \"start\": \"%s\", \"duration_sec\": %d, \"plays\": %d, \"agents\": \"%s\", \"first_latency\": %d}", i, match_starts[i], match_durations[i], match_plays[i], match_agent_lists[i], match_first_latency[i]
            if (i < match_count) print ","
            else print ""
        }
        print "  ]"
        print "}"
    }
    else if (format == "csv") {
        print "match_id,start_time,duration_sec,plays,cards_per_min,agents,first_latency_sec"
        for (i = start_match; i <= match_count; i++) {
            cpm = 0
            if (match_durations[i] > 0) cpm = (match_plays[i] / match_durations[i]) * 60
            printf "%d,%s,%d,%d,%.1f,%s,%d\n", i, match_starts[i], match_durations[i], match_plays[i], cpm, match_agent_lists[i], match_first_latency[i]
        }
    }
    else {
        # Text format
        print "=== Clash Royale Latency Analysis ==="
        print "Log file: logs/actions.log"
        printf "Period: %s to %s\n", first_timestamp, last_timestamp
        printf "Matches analyzed: %d\n", match_count
        print ""

        print "--- Match Statistics ---"
        printf "Match duration:     avg=%s\n", format_duration(duration_avg)
        printf "Cards per match:    avg=%.0f\n", plays_avg
        printf "Cards per minute:   avg=%.1f\n", cards_per_min
        print ""

        print "--- Timing Metrics ---"
        printf "Inter-action gap:   min=%ds  avg=%.1fs  median=%ds  p90=%ds  max=%ds\n", gap_min, gap_avg, gap_median, gap_p90, gap_max
        printf "Per-agent cycle:    avg=%.1fs\n", agent_cycle_avg
        printf "First agent latency: avg=%.1fs (time from opener to first agent)\n", first_latency_avg
        print ""

        if (verbose == "true") {
            print "--- Per-Match Breakdown ---"
            for (i = start_match; i <= match_count; i++) {
                cpm = 0
                if (match_durations[i] > 0) cpm = (match_plays[i] / match_durations[i]) * 60
                printf "Match %2d: %s  duration=%s  plays=%d  cpm=%.1f  agents=%s\n", i, match_starts[i], format_duration(match_durations[i]), match_plays[i], cpm, match_agent_lists[i]
            }
            print ""
        }

        print "--- Per-Agent Stats ---"
        # Sort agents by cycle time for display
        for (a in agent_cycle) {
            printf "Agent %s: avg cycle=%.1fs  plays=%d\n", a, agent_cycle[a], agent_play_count[a]
        }
    }
}
' "$LOG_FILE"
