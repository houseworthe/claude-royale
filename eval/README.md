# Screenshot Evaluation System

Test agent perception and decision-making against labeled screenshots.

## Quick Start

**During a match:**
```
You: "capture"
Claude: [Takes screenshot, saves to eval/screenshots/]
```

**After the match:**
```
You: "label eval/screenshots/2026-01-18_143052.png"
Claude: [Shows screenshot] What do you see?
You: "6 elixir, MP bomber wizard giant, Hog attacking left, play MP at 3F"
Claude: [Structures and saves to eval/labels/]
```

---

## Label Schema

```json
{
  "screenshot_id": "2026-01-18_143052",
  "screenshot_path": "eval/screenshots/2026-01-18_143052.png",

  "perception": {
    "elixir": 7,
    "hand": ["Mini P.E.K.K.A", "Bomber", "Wizard", "Giant"],
    "threats": [
      {"unit": "Hog Rider", "lane": "left", "severity": "high"}
    ],
    "tower_health": {
      "left": 2400,
      "right": 3000,
      "king": 4000
    }
  },

  "decision": {
    "primary": {
      "card": "Mini P.E.K.K.A",
      "slot": 1,
      "placement": "3F",
      "reasoning": "Tank killer on Hog before it hits tower"
    },
    "alternatives": [
      {"card": "Tombstone", "slot": 4, "placement": "4F", "validity": "acceptable"}
    ],
    "incorrect": [
      {"card": "Bomber", "placement": "6E", "why": "Wrong lane, cant stop Hog"}
    ]
  },

  "tags": ["defense", "hog_counter"],
  "difficulty": "medium"
}
```

---

## Fields Reference

### Perception

| Field | Type | Required | Example |
|-------|------|----------|---------|
| `elixir` | int (1-10) | Yes | `7` |
| `hand` | string[4] | Yes | `["Mini P.E.K.K.A", "Bomber", "Wizard", "Giant"]` |
| `threats` | object[] | No | `[{"unit": "Hog Rider", "lane": "left", "severity": "high"}]` |
| `tower_health` | object | No | `{"left": 2400, "right": 3000, "king": 4000}` |

**Threat severity levels:** `low`, `medium`, `high`, `critical`

### Decision

| Field | Type | Required | Example |
|-------|------|----------|---------|
| `primary.card` | string | Yes | `"Mini P.E.K.K.A"` |
| `primary.slot` | int (1-4) | Yes | `1` |
| `primary.placement` | string | Yes | `"3F"` |
| `primary.reasoning` | string | Yes | `"Kill Hog"` |
| `alternatives` | object[] | No | See schema |
| `incorrect` | object[] | No | See schema |

**Alternative validity:** `optimal`, `acceptable`, `suboptimal`

---

## Shorthand

When labeling, you can use shorthand:

**Cards:**
- `MP` = Mini P.E.K.K.A
- `MM` = Mega Minion
- `TS` = Tombstone
- `Arch` = Archers
- `Valk` = Valkyrie
- `Wiz` = Wizard

**Placements:**
- Grid: `3F`, `6G`, `2E`
- Natural: "left bridge", "behind king", "center"

**Threats:**
- `"Hog left"` = Hog Rider attacking left lane
- `"Giant+Witch right"` = Giant with Witch support on right

---

## Deck Reference (Slots 1-8)

| Slot | Card | Cost | Role |
|------|------|------|------|
| 1 | Mini P.E.K.K.A | 4 | Tank killer |
| 2 | Bomber | 2 | Ground splash |
| 3 | Mega Minion | 3 | Air defense |
| 4 | Tombstone | 3 | Building/pull |
| 5 | Archers | 3 | Ranged DPS |
| 6 | Giant | 5 | Primary tank |
| 7 | Valkyrie | 4 | Splash tank |
| 8 | Wizard | 5 | Splash + air |

Note: Hand shows 4 cards at a time. Slots rotate as cards are played.

---

## Grid Reference

```
     Col 1   2   3   4   5   6   7   8
         LEFT LANE    |    RIGHT LANE
     ┌───┬───┬───┬───┬───┬───┬───┬───┐
Row A│   │   │   │   │   │   │   │   │ Enemy
Row D│   │   │   │   │   │   │   │   │ half
     ├~~~┼~~~┼~~~┼~~~┼~~~┼~~~┼~~~┼~~~┤ RIVER
Row E│   │   │   │   │   │   │   │   │ Bridge
Row H│   │   │   │   │   │   │   │   │ King
     └───┴───┴───┴───┴───┴───┴───┴───┘
```

- **Rows A-D:** Enemy side (spells only)
- **Row E:** At bridge (aggressive)
- **Rows F-G:** Standard defense
- **Row H:** Deep/king tower

---

## Directory Structure

```
eval/
  README.md          # This file
  grading.json       # Scoring rubric
  screenshots/       # Raw screenshots to label
  labels/            # JSON label files
  results/           # Agent evaluation outputs
```
