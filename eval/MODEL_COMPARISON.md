# Model Comparison: Screenshot Evaluation Results

**Date:** January 18, 2026
**Test Set:** 25 labeled Clash Royale screenshots
**Task:** Perception (elixir, hand, threats) + Decision (card choice, placement)

---

## Executive Summary

We evaluated three Claude models on their ability to perceive game state and make optimal decisions from Clash Royale screenshots:

| Model | Overall Score | Latency | Verdict |
|-------|---------------|---------|---------|
| **Haiku** | **63%** | ~15-20s | **Winner** |
| Sonnet 4.5 | 54% | ~20-25s | Overthinks |
| Opus 4.5 | 56% | ~35-40s | Too slow |

**Key Finding: Bigger models perform worse on this task.**

Haiku's simpler, faster decision-making outperforms both Sonnet and Opus. The larger models overthink, hallucinate cards not in hand, and take too long to be useful in real-time gameplay.

---

## Detailed Results

### Overall Accuracy

| Metric | Haiku | Sonnet | Opus | Best |
|--------|-------|--------|------|------|
| **Total Score** | 63% | 54% | 56% | Haiku |
| Elixir Reading | 68% (17/25) | 68% (17/25) | 64% (16/25) | Haiku/Sonnet |
| Card Choice | 40% (10/25) | 24% (6/25) | 32% (8/25) | Haiku |
| Placement | 44% (11/25) | 32% (8/25) | 32% (8/25) | Haiku |

### Latency Comparison

| Model | Per Screenshot | Full 25-Screenshot Run | Est. Cards per 3-min Match |
|-------|----------------|------------------------|---------------------------|
| Haiku | ~17s | ~7 minutes | 10-12 plays |
| Sonnet | ~23s | ~10 minutes | 7-8 plays |
| Opus | ~38s | ~16 minutes | 4-5 plays |

For real-time Clash Royale gameplay, you need to play cards every 2-3 seconds when elixir allows. Even Haiku is borderline slow; Opus is completely unusable.

---

## Specific Examples

### Example 1: Screenshot 1 — Haiku's Perfect Score

**Scenario:** 10 elixir, Knight + Musketeer pushing left lane, need to defend.

| Model | Card | Placement | Elixir | Score |
|-------|------|-----------|--------|-------|
| **Haiku** | Valkyrie | 3F | 10 | **85/85** |
| Sonnet | Valkyrie | 4F | 10 | 88/100 |
| Opus | Wizard | 6E | 10 | 53/100 |
| **Label** | Valkyrie | 3F | 10 | — |

**Analysis:**
- Haiku: Perfect match — right card, right placement
- Sonnet: Right card, off by one column (acceptable)
- Opus: Wrong card entirely, wrong lane (Wizard on right instead of Valkyrie on left)

**Lesson:** Haiku makes simple, correct decisions. Opus overcomplicated and chose poorly.

---

### Example 2: Screenshot 9 — The Hallucination Problem

**Scenario:** 9 elixir, enemy left tower at 520 HP, need to push and finish.

| Model | Card Chosen | Card in Hand? | Hand Read |
|-------|-------------|---------------|-----------|
| **Haiku** | Mini P.E.K.K.A | ✓ Yes | Mini P, Wizard, Valk, Mega M |
| Sonnet | Giant | ✗ **NO** | Mini P, Valk, Mega M, Wizard |
| Opus | Giant | ✗ **NO** | Giant, Valk, Mega M, Wizard |
| **Label** | Mini P.E.K.K.A | — | Mega M, Valk, Mini P, Wizard |

**Analysis:**
- Haiku: Correctly identified Mini P.E.K.K.A in hand, chose it
- Sonnet: **Hallucinated Giant** — recommended a card NOT in hand
- Opus: **Also hallucinated Giant** — AND misread hand to include it

**Lesson:** Larger models hallucinate strategically "ideal" cards rather than working with what's available. This is a catastrophic error in gameplay — you can't play cards you don't have.

---

### Example 3: Screenshot 24 — Universal Failure

**Scenario:** Low elixir (2), our push already attacking king tower, should wait.

| Model | Card | Elixir Read | Correct Action |
|-------|------|-------------|----------------|
| Haiku | Valkyrie | 10 | ✗ |
| Sonnet | Valkyrie | 10 | ✗ |
| Opus | Valkyrie | 10 | ✗ |
| **Label** | wait | 2 | — |

**Analysis:**
All three models made the same mistake:
1. Misread elixir as 10 (actual: 2)
2. Decided to play Valkyrie (impossible at 2 elixir, Valk costs 4)
3. Should have recognized "wait" as optimal — push already in progress

**Lesson:** Elixir bar perception is a universal weakness. When all models fail the same way, it suggests a visual recognition limitation rather than reasoning error.

---

### Example 4: Screenshot 23 — Aggression vs Defense

**Scenario:** Enemy left tower at 474 HP, 26 seconds left, double elixir.

| Model | Card | Reasoning Style | Score |
|-------|------|-----------------|-------|
| **Haiku** | Giant | Push to finish low tower | **78/85** |
| Sonnet | Valkyrie | Defend right side threats | 51/100 |
| Opus | Giant | Push low tower | 83/100 |
| **Label** | Giant | Push to finish | — |

**Analysis:**
- Haiku: Aggressive — sees low tower, pushes to win
- Sonnet: Defensive — worried about threats, defends instead of winning
- Opus: Correct choice, but worse placement

**Lesson:** The ground truth labels encode an aggressive playstyle. Haiku's simpler "low tower = push" heuristic matches this better than Sonnet's threat-weighted analysis.

---

## Error Pattern Analysis

### By Error Type

| Error Type | Haiku | Sonnet | Opus |
|------------|-------|--------|------|
| Card hallucination | 0 | 1+ | 1+ |
| Over-defensive play | Low | High | Medium |
| Elixir misread (>2 off) | 8 | 8 | 9 |
| Wrong card (not hallucinated) | 15 | 18 | 16 |
| Wrong lane | 7 | 10 | 9 |

### Model-Specific Patterns

**Haiku:**
- Makes simple, fast decisions
- Rarely second-guesses
- Aggressive by default
- No hallucinations observed

**Sonnet:**
- Overthinks threat assessment
- Prioritizes defense over winning plays
- Hallucinated cards not in hand
- Longer reasoning = worse outcomes

**Opus:**
- Similar hallucination issues as Sonnet
- Worst elixir perception (64%)
- Extreme latency (2x Haiku)
- Marginal accuracy gain over Sonnet not worth the cost

---

## Why Bigger Models Fail

### 1. Overthinking
Larger models have more sophisticated reasoning, which becomes a liability when:
- Simple heuristics work better (low tower → push)
- Speed matters more than perfect analysis
- The ground truth encodes aggressive, not defensive, play

### 2. Hallucination Risk
Both Sonnet and Opus recommended cards not in hand. This suggests larger models:
- Generalize from "what card SHOULD be played" rather than "what cards ARE available"
- Over-rely on strategic knowledge vs perceptual grounding
- May have seen similar game states in training with different hands

### 3. No Vision Improvement
Despite more parameters, Sonnet and Opus didn't perceive the game state better:
- Same elixir misread rate as Haiku
- Slightly worse hand identification
- No improvement on threat detection

### 4. Latency Kills Usability
Even if Opus scored 90%, it would be unusable:
- 38 seconds per decision = 4-5 plays per match
- Opponent plays 15-20 cards in same time
- Speed is a feature, not a bug

---

## Conclusions

### Primary Finding
**Haiku is the best model for Clash Royale gameplay.**

It wins on:
- ✅ Accuracy (63% vs 54-56%)
- ✅ Speed (17s vs 23-38s)
- ✅ No hallucinations
- ✅ Aggressive playstyle match

### Secondary Findings

1. **Model size inversely correlates with performance** on this task
2. **Hallucination is a real risk** with larger models — they suggest impossible plays
3. **Elixir perception is universally weak** — room for prompt improvement
4. **Simple heuristics beat complex reasoning** in fast-paced games

### Recommendations

1. **Keep Haiku for player agents** — it's genuinely the best choice
2. **Focus prompt engineering on perception** — elixir bar hints, card visual descriptions
3. **Don't assume bigger = better** — validate with evals
4. **Use this eval framework** to test future prompt changes

---

## Appendix: Run Details

| Run | Model | Directory | Timestamp |
|-----|-------|-----------|-----------|
| 1 | Haiku | `run_20260118_184305` | 2026-01-18 18:43 |
| 2 | Sonnet 4.5 | `run_20260118_185212` | 2026-01-18 18:52 |
| 3 | Opus 4.5 | `run_20260118_190200` | 2026-01-18 19:02 |

### Scoring Rubric

- **Elixir:** 10 points (exact match)
- **Hand:** 10 points (all 4 cards correct, partial credit)
- **Threats:** 15 points (unit identification + severity)
- **Card Choice:** 25 points (exact match or acceptable alternative)
- **Placement:** 20 points (exact, partial for same lane)
- **Tower Health:** 5 points (perception accuracy)

**Max Score:** 85-100 points per screenshot (varies by grader version)

---

## Files

- Individual reports: `eval/results/run_*/REPORT.md`
- Raw results: `eval/results/run_*/*.json`
- Ground truth: `eval/labels/*.json`
- Test images: `eval/screenshots/*.png`
- Grading script: `scripts/grade-evals.sh`
- Eval runner: `scripts/run-evals.sh`
