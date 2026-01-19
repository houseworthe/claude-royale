# Evaluation System Design

How our eval system aligns with Anthropic's [Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents).

---

## Overview

We have two complementary evaluation systems:

| System | Type | Purpose |
|--------|------|---------|
| **Latency Analysis** | Production monitoring | Measure real-time performance metrics |
| **Screenshot Evaluation** | Capability eval | Test perception and decision-making |

---

## 1. Screenshot Evaluation System

### Article Alignment

| Best Practice | Our Implementation | Status |
|---------------|-------------------|--------|
| **"Start with 20-50 tasks"** | 25 labeled screenshots | ✅ |
| **"Derive from actual failures"** | Screenshots from real matches | ✅ |
| **"Write unambiguous tasks"** | Labels have `primary` + `alternatives` + `incorrect` | ✅ |
| **"Include reference solutions"** | Each label has reasoning for correct play | ✅ |
| **"Partial credit for multi-component tasks"** | Scoring breakdown by component | ✅ |
| **"Grade outcomes, not paths"** | Accepts alternative valid plays | ✅ |
| **"Build stable environments"** | Timestamped run directories isolate each eval | ✅ |
| **"Design thoughtful graders"** | `grading.json` defines rubric | ✅ |
| **"pass@k and pass^k metrics"** | `aggregate-evals.sh` with 90% threshold | ✅ |

### Grader Type: Hybrid

Per the article's three grader types:

1. **Code-based grader** (`grade-evals.sh`)
   - Fast, cheap, deterministic
   - Compares JSON fields against labels
   - Partial credit via tolerance bands

2. **Model-based execution** (Claude evaluates screenshots)
   - Flexible perception of visual input
   - Reads instructions from `player-eval.md` (single source of truth)

3. **Human labels** (ground truth)
   - Expert-created labels with primary/alternative/incorrect plays
   - Difficulty tagging for analysis

### Scoring Rubric (100 points)

```
Perception (40 pts)
├── Elixir:    10 pts (exact=10, off-by-1=7, off-by-2=4)
├── Hand:      10 pts (2.5 per correct card position)
├── Threats:   15 pts (count match=15, partial=8)
└── Towers:     5 pts (tolerance bands: within 200 HP)

Decision (60 pts)
├── Card:      25 pts (primary=25, alt-optimal=20, alt-acceptable=15, alt-suboptimal=10)
├── Placement: 20 pts (exact=20, same-lane=15, wrong-lane=5)
└── Reasoning: 15 pts (>50 chars=15, >30=10, >15=5)
```

### Pass Criteria

- **Threshold:** 90% (score ≥ 90/100)
- **pass@k:** Screenshot passed at least once in K runs
- **pass^k:** Screenshot passed every time in K runs

---

## 2. Latency Analysis System

### Article Alignment

This is **production monitoring**, not a capability eval. The article notes:

> "Automated evals work best alongside production monitoring"

| Metric | What It Measures |
|--------|------------------|
| Inter-action gap | Time between any card plays (all agents) |
| Per-agent cycle | Time between one agent's consecutive plays |
| Cards per minute | Overall play rate |
| First agent latency | Time from auto-opener to first agent play |

### Output Formats

- `--json` - Machine-readable for tracking over time
- `--csv` - Spreadsheet analysis
- `--verbose` - Per-match breakdown

### Future: Regression Thresholds

Currently reports metrics without pass/fail. Could add:
```bash
MAX_INTER_ACTION_GAP=5   # Alert if exceeded
MIN_CARDS_PER_MINUTE=8   # Alert if below
```

---

## Directory Structure

```
eval/
├── EVAL_DESIGN.md       # This document
├── README.md            # Quick start guide
├── grading.json         # Scoring rubric (source of truth)
├── screenshots/         # Test screenshots (1.png - 25.png)
├── labels/              # Ground truth JSON labels
└── results/
    ├── run_TIMESTAMP/   # Single eval run
    │   ├── 1.json       # Agent output for screenshot 1
    │   └── summary.json # Grading summary
    └── batch_TIMESTAMP/ # Multi-run for pass@k
        ├── batch.json   # Batch metadata
        ├── run_1/       # First run
        ├── run_2/       # Second run
        └── aggregate.json # pass@k metrics
```

---

## Scripts

| Script | Purpose |
|--------|---------|
| `run-evals.sh [start] [end]` | Run single eval pass |
| `grade-evals.sh <results_dir>` | Grade results against labels |
| `run-evals-multi.sh [k] [start] [end]` | Run K times for consistency |
| `aggregate-evals.sh <batch_dir>` | Calculate pass@k metrics |
| `analyze-latency.sh [options]` | Production timing analysis |

---

## Workflow

### Single Evaluation Run
```bash
./scripts/run-evals.sh 1 25
./scripts/grade-evals.sh eval/results/run_TIMESTAMP
```

### Consistency Testing (pass@k)
```bash
./scripts/run-evals-multi.sh 3        # Run 3 times
./scripts/aggregate-evals.sh eval/results/batch_TIMESTAMP
```

### Production Monitoring
```bash
./scripts/analyze-latency.sh --today --verbose
```

---

## Key Design Decisions

### 1. Single Source of Truth for Agent Instructions

The eval agent reads `.claude/agents/player-eval.md` rather than using an inline prompt. This ensures:
- Eval tests the same instructions used in production
- Updates to agent behavior automatically apply to evals
- No drift between eval prompt and real agent

### 2. Partial Credit Over Binary Pass/Fail

The article recommends:
> "Incorporate partial credit for multi-component tasks"

Our scoring allows:
- Off-by-one elixir: 7/10 pts (not 0)
- Same lane but wrong cell: 15/20 pts
- Alternative acceptable play: 15/25 pts

### 3. Alternative Valid Solutions

The article warns against:
> "Brittle grading: Penalizing valid alternative solutions"

Our labels include:
```json
"alternatives": [
  {"card": "Mega Minion", "validity": "acceptable", "reasoning": "Also works"}
]
```

### 4. Isolated Test Runs

Each eval run gets a timestamped directory. No shared state between runs, preventing:
- Correlated failures from infrastructure issues
- Performance inflation from cached results

---

## Future Improvements

### From the Article

| Recommendation | Status | Notes |
|----------------|--------|-------|
| Negative test cases | Partial | Some "wait" cases exist, could add more |
| Catastrophic failure penalties | Not implemented | grading.json has `-10` but not enforced |
| Saturation tracking | Not implemented | Track when 100% is too easy |
| Difficulty progression | Partial | Labels have difficulty tags, not stratified |

### Potential Additions

1. **Stratified test sets** - Separate easy/medium/hard screenshot pools
2. **Regression suite** - Subset that must always pass
3. **Baseline comparison** - `--compare <previous_run>` for delta analysis
4. **Component-level reasoning scoring** - Parse reasoning for threat/counter/timing keywords

---

## References

- [Demystifying Evals for AI Agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) - Anthropic Engineering
- `eval/grading.json` - Full scoring rubric
- `.claude/agents/player-eval.md` - Agent instructions
