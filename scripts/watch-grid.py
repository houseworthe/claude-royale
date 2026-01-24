#!/usr/bin/env python3
"""
watch-grid.py - Visual grid display of agent card placements
Shows a live battlefield grid with card plays highlighted in real-time
"""

import sys
import os
import re
import time
from collections import deque

# ANSI color codes
class Colors:
    RESET = '\033[0m'
    BOLD = '\033[1m'
    DIM = '\033[2m'

    # Agent colors (foreground)
    RED = '\033[91m'
    GREEN = '\033[92m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    MAGENTA = '\033[95m'
    WHITE = '\033[97m'
    GRAY = '\033[90m'

    # Background colors
    BG_RED = '\033[41m'
    BG_GREEN = '\033[42m'
    BG_BLUE = '\033[44m'
    BG_YELLOW = '\033[43m'
    BG_CYAN = '\033[46m'
    BG_MAGENTA = '\033[45m'

AGENT_COLORS = [Colors.RED, Colors.GREEN, Colors.BLUE, Colors.YELLOW, Colors.CYAN, Colors.MAGENTA]
AGENT_BG = [Colors.BG_RED, Colors.BG_GREEN, Colors.BG_BLUE, Colors.BG_YELLOW, Colors.BG_CYAN, Colors.BG_MAGENTA]

agent_color_map = {}
next_color_idx = 0

def get_agent_color(agent_id):
    global next_color_idx
    if agent_id not in agent_color_map:
        agent_color_map[agent_id] = next_color_idx
        next_color_idx = (next_color_idx + 1) % len(AGENT_COLORS)
    idx = agent_color_map[agent_id]
    return AGENT_COLORS[idx], AGENT_BG[idx]

def clear_screen():
    print('\033[2J\033[H', end='')

def draw_grid(recent_plays):
    """Draw the battlefield grid matching CLAUDE.md format"""

    cols = ['1', '2', '3', '4', '5', '6', '7', '8']
    rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']

    # Build cell content map from recent plays (last play wins)
    cell_content = {}
    for play in recent_plays:
        cell = play['cell'].upper()
        cell_content[cell] = play

    clear_screen()

    # Header
    print(f"{Colors.BOLD}{Colors.CYAN}╔═══════════════════════════════════════════════════════════════════╗{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}║{Colors.WHITE}           CLASH ROYALE - LIVE AGENT BATTLEFIELD                  {Colors.CYAN}║{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}╚═══════════════════════════════════════════════════════════════════╝{Colors.RESET}")
    print()

    # Column headers
    print(f"        {Colors.WHITE}Col 1   2   3   4   5   6   7   8{Colors.RESET}")
    print(f"           {Colors.RED}LEFT LANE{Colors.RESET}    {Colors.GRAY}|{Colors.RESET}    {Colors.BLUE}RIGHT LANE{Colors.RESET}")
    print(f"        ┌───┬───┬───┬───┬───┬───┬───┬───┐")

    for i, row in enumerate(rows):
        # Determine zone
        if row in ['A', 'B', 'C', 'D']:
            zone_color = Colors.RED
            zone_label = "Enemy"
        else:
            zone_color = Colors.GREEN
            zone_label = "Ours "

        # Row label
        print(f"  {Colors.YELLOW}Row {row}{Colors.RESET} │", end='')

        for j, col in enumerate(cols):
            cell_id = f"{col}{row}"

            if cell_id in cell_content:
                play = cell_content[cell_id]
                fg, bg = get_agent_color(play['agent'])
                # Show first 3 chars of card
                card_abbr = play['card'][:3]
                print(f"{bg}{Colors.WHITE}{card_abbr:^3}{Colors.RESET}│", end='')
            else:
                print(f"   │", end='')

        print(f" {zone_color}{zone_label}{Colors.RESET}")

        # River after row D
        if row == 'D':
            print(f"        ├~~~┼~~~┼~~~┼~~~┼~~~┼~~~┼~~~┼~~~┤ {Colors.CYAN}← RIVER{Colors.RESET}")

    print(f"        └───┴───┴───┴───┴───┴───┴───┴───┘")
    print()

    # Recent plays feed
    print(f"{Colors.BOLD}{Colors.WHITE}═══ LIVE FEED ═══{Colors.RESET}")

    plays_list = list(recent_plays)[-8:]  # Last 8 plays
    for play in reversed(plays_list):
        fg, _ = get_agent_color(play['agent'])
        age = time.time() - play['time']

        # Fresh indicator
        if age < 1:
            indicator = f"{Colors.WHITE}▶▶{Colors.RESET}"
        elif age < 3:
            indicator = f"{Colors.YELLOW}▶ {Colors.RESET}"
        else:
            indicator = "  "

        reason_short = play['reason'][:35] + "..." if len(play['reason']) > 35 else play['reason']
        print(f"{indicator} {fg}[{play['agent']}]{Colors.RESET} {Colors.WHITE}{play['card']:12}{Colors.RESET} → {Colors.YELLOW}{play['cell']:3}{Colors.RESET} {Colors.DIM}{reason_short}{Colors.RESET}")

    # Pad if fewer than 8 plays
    for _ in range(8 - len(plays_list)):
        print()

    print()
    print(f"{Colors.DIM}Watching logs/actions.log... Ctrl+C to exit{Colors.RESET}")

def parse_log_line(line):
    """Parse a log line and extract play info"""
    # Pattern: 2026-01-24 14:34:46 [k3p] PLAY slot=3 cell=3F card=Mini P.E.K.K.A reason="splash support"
    # Card names can have spaces (e.g., "Mini P.E.K.K.A", "Fire Spirit")
    match = re.match(r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(\w+)\] PLAY slot=(\d+) cell=(\w+) card=(.+?) reason="([^"]*)"', line)
    if match:
        return {
            'timestamp': match.group(1),
            'agent': match.group(2),
            'slot': match.group(3),
            'cell': match.group(4),
            'card': match.group(5).strip(),
            'reason': match.group(6),
            'time': time.time()
        }
    return None

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_dir = os.path.dirname(script_dir)
    log_file = os.path.join(project_dir, 'logs', 'actions.log')

    recent_plays = deque(maxlen=20)

    draw_grid(recent_plays)

    with open(log_file, 'r') as f:
        f.seek(0, 2)  # Seek to end

        last_draw = time.time()
        while True:
            line = f.readline()
            if line:
                play = parse_log_line(line.strip())
                if play:
                    recent_plays.append(play)
                    draw_grid(recent_plays)
                    last_draw = time.time()
            else:
                # Clear old plays periodically
                now = time.time()
                if now - last_draw > 1:
                    # Remove plays older than 8 seconds from grid
                    while recent_plays and now - recent_plays[0]['time'] > 8:
                        recent_plays.popleft()
                    draw_grid(recent_plays)
                    last_draw = now
                time.sleep(0.05)

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.RESET}Exiting...")
        sys.exit(0)
