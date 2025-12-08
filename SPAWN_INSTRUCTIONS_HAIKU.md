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

## OPENING CARD RULE (CRITICAL!)

**YOU MUST PLAY YOUR FIRST CARD WITHIN 5 SECONDS OF MATCH START.**

- Even if the board looks empty
- Even if you don't see opponent units yet
- This establishes tempo and forces opponent to react
- **DO NOT WAIT** for opponent to play first

---

## DEFENSIVE LANE LOGIC (CRITICAL!)

**ALWAYS check which lane opponent is attacking, then defend THAT lane:**

### OPPONENT ATTACKING LEFT LANE (columns 1-4, left side of screen):
- Defend by placing troops in columns 2-3, rows E-F
- **Examples:** `2E`, `3E`, `2F`, `3F`

### OPPONENT ATTACKING RIGHT LANE (columns 5-8, right side of screen):
- Defend by placing troops in columns 6-7, rows E-F
- **Examples:** `6E`, `7E`, `6F`, `7F`

### NO IMMEDIATE THREAT:
- Play offensive pressure: **Giant** at `3E` or `6E` (at bridge)
- Support with **Musketeer** at `3F` or `6F` (behind Giant)

**CRITICAL RULE:**
- **Opponent on LEFT (cols 1-4) = Defend LEFT (cols 2-3)**
- **Opponent on RIGHT (cols 5-8) = Defend RIGHT (cols 6-7)**
- **REACT to the threat. Don't always play the same side.**

---

## BATTLE LOOP (REPEAT UNTIL MATCH ENDS)

**Speed is EVERYTHING. You can play 1 OR 2 cards per loop based on elixir.**

```
LOOP:
1. ./scripts/screenshot.sh then READ the image
2. Check elixir bar (pink bar at bottom, number shown)
3. Look at hand (4 cards at bottom)
4. SCAN OPPONENT: Look for SMALL RED ICONS above troops
   - **ENEMY troops have small RED icons above them**
   - **YOUR troops have NO icons above them**
   - Enemy units on VISUALLY LEFT side (top-left) = Columns 7-8
   - Enemy units on VISUALLY RIGHT side (top-right) = Columns 5-6
5. DECIDE DEFENSE:
   - If opponent on TOP-RIGHT (columns 5-6) → Defend on YOUR BOTTOM-RIGHT (columns 3-4)
   - If opponent on TOP-LEFT (columns 7-8) → Defend on YOUR BOTTOM-LEFT (columns 1-2)
   - If no threat → Attack with Giant/Musketeer on YOUR BOTTOM-RIGHT (columns 3-4)
6. **BEFORE PLAYING - EXPLAIN YOUR REASONING OUT LOUD:**
   "I see opponent [TOP-LEFT/TOP-RIGHT/NONE]. I'm placing [CARD] at column [1-4] because [REASON]. This is YOUR [LEFT/RIGHT] side."
7. Play card(s): ./scripts/play_card.sh <slot 1-4> <grid>
8. sleep 0.3
9. REPEAT
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

## GRID SYSTEM - CRITICAL

```
            ENEMY SIDE (TOP OF SCREEN)
     Col 1    2    3    4    5    6    7    8
     x=622  691  760  828  897  966  1034 1103

y=286  1A   2A   3A   4A   5A   6A   7A   8A   Row A  ┐
y=342  1B   2B   3B   4B   5B   6B   7B   8B   Row B  │ ENEMY HALF
y=397  1C   2C   3C   4C   5C   6C   7C   8C   Row C  │ (spells only)
y=452  1D   2D   3D   4D   5D   6D   7D   8D   Row D  ┘
       ~~~~~~~~~~~  RIVER  ~~~~~~~~~~~
       [BRIDGE]                [BRIDGE]
y=540  1E   2E   3E   4E   5E   6E   7E   8E   Row E  ┐
y=670  1F   2F   3F   4F   5F   6F   7F   8F   Row F  │ CLAUDE HALF
y=800  1G   2G   3G   4G   5G   6G   7G   8G   Row G  │ (troops OK!)
y=880  1H   2H   3H   4H   5H   6H   7H   8H   Row H  ┘
            CLAUDE'S SIDE (BOTTOM)

LEFT LANE: Cols 1-4    RIGHT LANE: Cols 5-8
```

**Card Placement Format:** `./scripts/play_card.sh <slot 1-4> <column><row>`

**COLUMNS:** 1-8 go left to right across the arena
- **Columns 1-4** = LEFT LANE (toward left bridge)
- **Columns 5-8** = RIGHT LANE (toward right bridge)

**ROWS:** A-H go top to bottom
- **Rows A-D** = ENEMY HALF (spells only)
- **Rows E-H** = CLAUDE HALF (troops OK)
- **Row E** = At the bridge (aggressive)
- **Row H** = At king tower (defensive)

**PLACEMENT RULES:**
- **Troops:** Rows E-H only (your half)
- **Spells:** Can be placed ANYWHERE (rows A-H)
- **Left lane attack:** Columns 2-3, Row E
- **Right lane attack:** Columns 6-7, Row E

**Examples:**
- `3E` = Left lane at bridge (aggressive)
- `6E` = Right lane at bridge (aggressive)
- `2F` = Left lane, princess tower level
- `7F` = Right lane, princess tower level
- `3H` = Left side, deep defense
- `6H` = Right side, deep defense

---

## YOUR CARDS & STRATEGY

| Slot | Card | Cost | Visual | Strengths | Notes |
|------|------|------|--------|-----------|-------|
| 1 | Mini P.E.K.K.A | 4 | Dark blue armored figure with visor | Kills high-HP tanks (Giant, Hog, Knight) fast | Good for intercepting pushes |
| 2 | Bomber | 3 | Character with yellow goggles/rings | Splash damage, damages multiple units | **DEFENSE ONLY** - Never play alone for offense. Only use to defend or support a Giant push. |
| 3 | Mega Minion | 4 | Dark gray and purple flying creature with single target attack | **DEFENSE ONLY** - stops air units, medium health, single-target damage | Never play alone for offense. Only use to defend or support a Giant push. |
| 4 | Tombstone | 3 | Stone grave with skeleton hand sticking out | Defensive building that pulls/distracts troops, spawns skeletons | Works well in center areas to affect both lanes |
| 5 | Archers | 3 | One female character with pink hair | Ranged consistent DPS | **DEFENSE ONLY** - Never play alone for offense. Only use to defend or support a Giant push. |
| 6 | Giant | 5 | Large blue muscular character | **WIN CONDITION** - High HP tank | Most effective with Musketeer support behind it |
| 7 | Valkyrie | 4 | Female character with orange hair and axe | Tanky with splash damage | **DEFENSE ONLY** - place right on top of enemy swarms. Never play alone for offense. |
| 8 | Musketeer | 4 | Female character with purple hair and hat | Strong ranged DPS, stops air units | Pair with Giant for main pushes |

**KEY SYNERGIES:**
- **Giant + Musketeer** = Your main win condition beatdown
- **Valkyrie + Bomber** = Strong swarm clear
- **Tombstone works best** when placed to pull threats toward center (vs having enemies bypass it)
- **Mini P.E.K.K.A** = Best used on enemy tanks, less effective against small swarms

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
