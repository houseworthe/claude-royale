# Claude Royale

<p align="center">
  <img src="1000_milestone.png" width="450" alt="Claude reaches 1000 trophies">
</p>

A harness for AI agents to play Clash Royale autonomously.

## What is this?

Claude Royale is an open framework that lets AI systems play Clash Royale through screen capture and input automation. It handles the game interface, coordinate mapping, and action execution - you provide the AI decision-making.

The included implementation uses Claude Code with a multi-agent architecture: a Commander agent manages menus and game flow while spawning 3 parallel Player agents that work together to play each match.

**Current progress:** 1000+ trophies (Spell Valley - Arena 5)

**Live tested:** 12+ hours streamed on Twitch with Claude playing live

**Autonomy:** Claude played 5 games in a row autonomously, with minor human intervention only to close pop-ups and open chests

## How it works

```
Commander (Main Claude instance)
├── Manages menus, chests, upgrades
├── Taps "Battle" to start matches
├── Spawns 3 player sub-agents in parallel
└── Tracks trophies and updates memory

Player Sub-Agents (3 instances per match)
├── All three play the SAME match together
├── Each plays cards independently at max speed
├── Natural staggering creates continuous pressure
└── Stop at result screen, report back to Commander
```

**Why 3 agents?** We measured ~7 second latency between screenshot and action for each agent. Running 3 agents in parallel staggers their card plays, reducing effective latency and maintaining constant board pressure. As AI inference speeds improve, fewer agents may be needed.

## Learnings

### Slow Opening Cards
Early matches were lost because Claude took too long to play the first card - opponents would rush and take a tower before Claude reacted. We added an auto-opener that plays the first card at 5 seconds and a second card at 8 seconds after hitting the battle button. This establishes early tempo and forces the opponent to react rather than freely push.

### 7-Second Latency
We added debug logging to the sub-agents and discovered that the round-trip from screenshot → vision analysis → decision → tool call takes roughly 7 seconds. This is why we use 3 parallel agents playing the same match - their natural stagger means a card gets played approximately every 2-3 seconds. We look forward to this improving as AI inference speeds increase.

### Self-Directed Strategy
Claude researched its own deck strategy based on available cards, analyzed synergies, and wrote the `SPAWN_INSTRUCTIONS_HAIKU.md` file - a detailed gameplay prompt for the sub-agents covering card placement, lane defense logic, and elixir management. The human provided the harness; Claude developed the strategy.

### Result Screen Deception
The game displays "WINNER!" on every result screen - including losses. Early sessions had Claude celebrating losses because it trusted the banner. Now we verify wins/losses by checking the trophy delta (trophies up = win, down = loss).

### Agent Containment
Due to latency, sub-agents would sometimes attempt to play a card right as the result screen appeared - and accidentally tap "Play Again" instead, starting unsupervised solo matches. We restricted agents to only use `screenshot.sh` and `play_card.sh`, and added strict result screen detection to stop immediately when the match ends.

## Project Structure

```
claude-royale/
├── scripts/           # Game automation
│   ├── screenshot.sh  # Capture game screen
│   ├── play_card.sh   # Play card to grid position
│   ├── tap.sh         # Tap UI elements
│   └── get-chat.sh    # Twitch chat integration
├── config/
│   ├── coordinates.json  # UI element positions
│   └── gameplay.json     # Battle grid mappings
├── memory/            # Persistent knowledge
│   ├── STATUS.md      # Current trophies, session progress
│   ├── LEARNINGS.md   # Strategic knowledge
│   └── GOALS.md       # Objectives
├── CLAUDE.md          # Main instructions for Claude
├── SPAWN_INSTRUCTIONS_HAIKU.md  # Player agent protocol
└── twitch-chat.js     # Twitch chat collector
```

## Requirements

- macOS
- [BlueStacks](https://www.bluestacks.com/) with Clash Royale installed
- [Claude Code](https://claude.ai/claude-code) CLI
- Node.js (for Twitch chat integration)
- `cliclick` for mouse automation (`brew install cliclick`)
- `jq` for JSON parsing (`brew install jq`)

## Setup

1. Clone the repo
2. Install dependencies: `npm install`
3. Position BlueStacks window at screen origin (0, 33)
4. Run `./scripts/calibrate.sh` if coordinates need adjustment
5. Start Claude Code in the project directory

## Usage

Just tell Claude to play:

```
> Play some matches
> Check your trophy count
> What did you learn from that loss?
```

Claude reads `CLAUDE.md` for instructions and manages everything autonomously - starting battles, playing cards, handling menus, and tracking progress.

## Current Progress

- **Trophies:** 1000+
- **Arena:** Spell Valley (Arena 5)
- **Goal:** ~~Reach 1000 trophies~~ ACHIEVED

## Features

- **Multi-agent battles:** 3 parallel agents for faster, more aggressive play
- **Auto-opener:** First card played within 8 seconds of match start
- **Persistent memory:** Learns from wins and losses across sessions
- **Twitch integration:** Can read and respond to chat while streaming
- **2v2 mode:** Can play cooperative matches with a human partner

## The Deck

Giant + Musketeer beatdown (3.75 avg elixir):
- Giant, Musketeer, Valkyrie, Mini P.E.K.K.A
- Archers, Bomber, Mega Minion, Tombstone

## Can I use this?

**Not yet** - this is a personal project and isn't packaged for general use. The coordinate system is hardcoded for my specific BlueStacks window position and resolution. If you wanted to run this yourself, you'd need to redo all the button coordinates in `config/coordinates.json` and `config/gameplay.json` for your setup.

That said, the architecture and approach are documented if you want to build something similar. Just clone the repo and paste this prompt into Claude Code:

```
Analyze this repo. I want to create my own version. Rip out all the specific data that's tied to the current user and let's get started with a blank slate. We are going to make a new agent.
```

## Future Improvements

- **Twitch chat responses** - Allow Claude to send messages back to stream chat ([#1](https://github.com/houseworthe/claude-royale/issues/1))
- **Navigation system** - Comprehensive screen identification and button mapping so Claude can navigate the full Clash Royale app ([#2](https://github.com/houseworthe/claude-royale/issues/2))
- **2v2 accept button fix** - Bug fix for Claude not tapping the accept button in 2v2 mode ([#3](https://github.com/houseworthe/claude-royale/issues/3))

---

Built over a weekend. December 2025.
