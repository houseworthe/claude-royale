# How to Spawn New Claude Royale Instances

## Quick Reference

When you want to spawn a new instance, tell Claude Code one of these exact messages:

### To Spawn a Game Player:

```
You are Player 1. Read the section in CLAUDE.md called "PLAYER ROLE: MATCH EXECUTION ONLY"
and follow ONLY those instructions. Your job: Play matches at maximum speed. Use sleep 0.5 only.
No menus, no upgrades, no clicking OK buttons. When the match ends and you see the result screen, STOP.
Don't dismiss it. Start by taking a screenshot to see the current game state.
```

Or if spawning multiple players:

```
You are Player 2. Read the section in CLAUDE.md called "PLAYER ROLE: MATCH EXECUTION ONLY"
and follow ONLY those instructions. Your job: Play matches at maximum speed. Use sleep 0.5 only.
No menus, no upgrades, no clicking OK buttons. When the match ends and you see the result screen, STOP.
Don't dismiss it. Start by taking a screenshot to see the current game state.
```

```
You are Player 3. [same instructions as Player 2, just change "Player 3"]
```

### To Spawn the Commander:

```
You are the Commander. Read the section in CLAUDE.md called "COMMANDER ROLE: GAME STATE MANAGEMENT"
and follow ONLY those instructions. Your job: Manage the game state between matches. Handle menus,
chests, upgrades, and coordinate the next match. Verify trophy count after each result (don't trust
the "WINNER!" label). Update STATUS.md with results. Use sleep 1-2 for menu actions (no rush).
Start by taking a screenshot to see the current game state.
```

---

## How It Works

1. **Spawn Players first** (if you want multiple): Tell Claude "You are Player 1", "You are Player 2", etc.
2. **Spawn Commander last**: Tell Claude "You are the Commander"
3. **Each instance reads their role section** in CLAUDE.md
4. **Players only play matches** - they ignore all menu tasks
5. **Commander coordinates** - starts matches, dismisses results, updates memory files

---

## What to Expect

### Players
- Will wait until a match starts
- Will play cards rapidly (sleep 0.5 between actions)
- Will STOP immediately when result screen appears
- Will NOT click OK or dismiss anything
- Will be very fast and focused

### Commander
- Will check game state continuously
- Will dismiss result screens
- Will select rewards
- Will start new matches
- Will update STATUS.md with accurate results (checking trophy count)
- Will move more slowly (sleep 1-2 is fine)

---

## Example: Spawning 3 Players + 1 Commander

```
1. Tell Claude: "You are Player 1. Read CLAUDE.md section PLAYER ROLE..." [paste instructions above]
2. (Wait for Player 1 to acknowledge and take screenshot)
3. Tell Claude: "You are Player 2. Read CLAUDE.md section PLAYER ROLE..." [paste instructions]
4. (Wait for Player 2 to acknowledge and take screenshot)
5. Tell Claude: "You are Player 3. Read CLAUDE.md section PLAYER ROLE..." [paste instructions]
6. (Wait for Player 3 to acknowledge and take screenshot)
7. Tell Claude: "You are the Commander. Read CLAUDE.md section COMMANDER ROLE..." [paste instructions]
8. (Wait for Commander to acknowledge and take screenshot)
```

Now:
- Players are waiting (taking screenshots periodically)
- Commander starts the loop of: battle → match → dismiss result → start next battle
- Players come alive when matches start, disappear when matches end
- System runs smoothly with no interference

---

## Key Safeguard: Role Enforcement

Each instance reads only their role section and ignores everything else. This prevents:
- ❌ Players clicking OK buttons and interfering
- ❌ Multiple instances trying to start matches simultaneously
- ❌ Contention on menu actions
- ❌ Race conditions on reward selection

**Each instance knows exactly what it's supposed to do and ONLY does that.**
