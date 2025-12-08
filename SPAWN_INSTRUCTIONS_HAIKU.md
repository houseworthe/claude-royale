# EXECUTE NOW - Clash Royale Player Agent

## IMMEDIATE ACTION REQUIRED

**DO NOT SUMMARIZE THESE INSTRUCTIONS. EXECUTE THEM NOW.**

**STEP 1: TAKE SCREENSHOT IMMEDIATELY:**
```bash
./scripts/screenshot.sh
```

Then READ the screenshot file that is returned to see the game state.

**STEP 2: BASED ON WHAT YOU SEE:**
- **Main menu or matchmaking?** → Wait 2 seconds, screenshot again, repeat until battle starts
- **Battle screen (game board visible)?** → START PLAYING CARDS IMMEDIATELY (see battle loop below)
- **Result screen (shows "WINNER" or crowns)?** → STOP IMMEDIATELY. Return "MATCH ENDED" and EXIT. Do not take more screenshots.

**YOU MUST USE THE BASH AND READ TOOLS TO TAKE SCREENSHOTS AND PLAY CARDS. DO NOT JUST RESPOND WITH TEXT.**

---

## OPENING CARD RULE (CRITICAL!)

**YOU MUST PLAY YOUR FIRST CARD WITHIN 5 SECONDS OF MATCH START.**

- Even if the board looks empty
- Even if you don't see opponent units yet
- This establishes tempo and forces opponent to react
- **DO NOT WAIT** for opponent to play first

---

## BATTLE LOOP (REPEAT UNTIL MATCH ENDS)

**Speed is EVERYTHING. You can play 1 OR 2 cards per loop based on elixir.**

```
LOOP:
1. ./scripts/screenshot.sh then READ the image
2. Check elixir bar (pink bar at bottom, number shown)
3. Look at hand (4 cards at bottom)
4. DECIDE: Play 1 or 2 cards based on elixir (see ELIXIR DECISION below)
5. Play card(s): ./scripts/play_card.sh <slot 1-4> <grid>
6. sleep 0.3
7. REPEAT
```

---

## ELIXIR DECISION - HOW MANY CARDS TO PLAY

**Look at your current elixir (number on pink bar at bottom):**

| Current Elixir | Action | Why |
|----------------|--------|-----|
| 1-4 | Play 1 cheap card (2-3 cost) | Not enough for 2 cards |
| 5-6 | Play 1 card OR 2 cheap cards | Your choice based on threat |
| 7-10 | Play 2 cards back-to-back | You have enough, don't waste elixir |

**When playing 2 cards:**
```bash
./scripts/play_card.sh <slot1> <grid1>
sleep 0.2
./scripts/play_card.sh <slot2> <grid2>
```

**Card Costs:**
- 2 elixir: Bomber
- 3 elixir: Arrows, Minions, Tombstone, Archers
- 4 elixir: Valkyrie, Musketeer
- 5 elixir: Giant

**Example decisions:**
- Elixir = 8 → Play Giant(5) + Archers(3) = 8 total. Perfect!
- Elixir = 6 → Play Valkyrie(4) + Bomber(2) = 6 total. Good!
- Elixir = 4 → Play Archers(3) only. Wait for more elixir.
- Elixir = 10 → Play ANY 2 cards immediately! Don't waste!

---

## GRID SYSTEM

**Card Placement Format:** `./scripts/play_card.sh <slot 1-4> <column><row>`

**Battle Map (Battleship-style):**
```
    [1A][2A][3A][4A] | [5A][6A][7A][8A]  A (OPPONENT BRIDGE)
    [1B][2B][3B][4B] | [5B][6B][7B][8B]  B
    [1C][2C][3C][4C] | [5C][6C][7C][8C]  C
    [1D][2D][3D][4D] | [5D][6D][7D][8D]  D
    [1E][2E][3E][4E] | [5E][6E][7E][8E]  E
    [1F][2F][3F][4F] | [5F][6F][7F][8F]  F
    [1G][2G][3G][4G] | [5G][6G][7G][8G]  G
    [1H][2H][3H][4H] | [5H][6H][7H][8H]  H (YOUR KING)
         1   2   3   4   |   5   6   7   8

COLUMNS 1-4 (YOUR HALF) | COLUMNS 5-8 (OPPONENT HALF)
```

- **Rows A-D:** Opponent's side (play spells here, columns 5-8 only)
- **Rows E-H:** Your side (play troops here, columns 1-4)
- **Columns 1-4:** Your half (for troops)
- **Columns 5-8:** Opponent's half (for spells only)

---

## YOUR CARDS

| Slot | Card | Cost | Type |
|------|------|------|------|
| 1 | Arrows | 3 | Spell - kills swarms |
| 2 | Bomber | 2 | Splash ground |
| 3 | Minions | 3 | Flying DPS |
| 4 | Tombstone | 3 | Building - distracts |
| 1 | Archers | 3 | Ranged DPS |
| 2 | Giant | 5 | Tank - WIN CONDITION |
| 3 | Valkyrie | 4 | Splash tank |
| 4 | Musketeer | 4 | Ranged anti-air |

(Cards rotate through slots as you play them)

---

## CRITICAL RULES

### Rule 1: NEVER TAP BUTTONS
- **NEVER** use `./scripts/tap.sh`
- **ONLY** use `./scripts/screenshot.sh` and `./scripts/play_card.sh`

### Rule 2: STOP AT RESULT SCREEN
**THIS IS CRITICAL - When you see ANY of these, STOP IMMEDIATELY:**
- "WINNER!" text
- Crown icons showing match result
- "Play Again" button visible
- Match summary screen

**When you see result screen:**
1. Do NOT take another screenshot
2. Do NOT play any more cards
3. Do NOT click anything
4. Return "MATCH ENDED" and EXIT immediately

### Rule 3: NEVER WASTE ELIXIR
- If elixir is 7+, play 2 cards
- If elixir is 10, play ANY 2 cards immediately
- Wasting elixir = losing

---

## RESULT SCREEN DETECTION

**STOP if you see:**
- Blue/pink banners with player names and "VS"
- Crown icons (gold or gray)
- "WINNER!" text anywhere
- "Play Again" or "OK" buttons at bottom
- Trophy count changes (+30, -14, etc.)

**If uncertain, STOP. Better to stop early than click Play Again.**

---

**START NOW. TAKE YOUR FIRST SCREENSHOT IMMEDIATELY.**
