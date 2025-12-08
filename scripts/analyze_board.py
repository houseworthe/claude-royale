#!/usr/bin/env python3
"""
analyze_board.py - Use local Moondream vision model to describe game state
Usage: ./analyze_board.py [screenshot_path]
Returns: Text description of game state for Haiku to process
"""

import subprocess
import urllib.request
import json
import base64
import time
import sys
import os

# Configuration
OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "moondream"
SCREENSHOT_PATH = "/tmp/cr_current.png"
BOUNDS = "560,36,610,1078"  # BlueStacks game area

PROMPT = """This is a Clash Royale mobile game screenshot. Analyze it and report:

SCREEN: battle / menu / result / loading
If RESULT screen: Say "RESULT" and stop.
If MENU screen: Say "MENU" and stop.

If BATTLE screen, continue with:
TIMER: time remaining (top center, like "2:15" or "0:45")
ELIXIR: number 0-10 (purple bar at bottom)

CARDS (4 slots at bottom, left to right):
1: [card name or "unknown"]
2: [card name or "unknown"]
3: [card name or "unknown"]
4: [card name or "unknown"]

BATTLEFIELD:
- Your troops (blue side, bottom half): list what you see and where
- Enemy troops (red side, top half): list what you see and where
- Towers: any damage visible?

THREAT: What needs immediate response?

Card reference: Giant (big bald guy), Musketeer (woman with rifle), Valkyrie (woman with axe), Archers (two women with bows), Bomber (small guy yellow goggles), Minions (3 blue flying), Tombstone (gravestone spawns skeletons), Arrows (spell - red streaks)

Be concise. Focus on troop positions."""


def take_screenshot(output_path):
    """Capture BlueStacks game area"""
    subprocess.run(
        ["screencapture", f"-R{BOUNDS}", output_path],
        check=True,
        capture_output=True
    )
    return os.path.exists(output_path)


def analyze_image(image_path):
    """Send image to Moondream via Ollama API"""
    with open(image_path, 'rb') as f:
        img_b64 = base64.b64encode(f.read()).decode('utf-8')

    payload = {
        "model": MODEL,
        "prompt": PROMPT,
        "images": [img_b64],
        "stream": False
    }

    req = urllib.request.Request(
        OLLAMA_URL,
        data=json.dumps(payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )

    with urllib.request.urlopen(req, timeout=60) as resp:
        result = json.loads(resp.read().decode('utf-8'))

    return result.get('response', 'ERROR: No response')


def main():
    start = time.time()

    # Get screenshot path from args or take new screenshot
    if len(sys.argv) > 1:
        screenshot_path = sys.argv[1]
        if not os.path.exists(screenshot_path):
            print(f"ERROR: File not found: {screenshot_path}", file=sys.stderr)
            sys.exit(1)
    else:
        screenshot_path = SCREENSHOT_PATH
        if not take_screenshot(screenshot_path):
            print("ERROR: Failed to take screenshot", file=sys.stderr)
            sys.exit(1)

    screenshot_time = time.time() - start

    # Analyze with vision model
    analyze_start = time.time()
    result = analyze_image(screenshot_path)
    analyze_time = time.time() - analyze_start

    total_time = time.time() - start

    # Output result
    print(result)
    print(f"\n[Screenshot: {screenshot_time:.2f}s | Analysis: {analyze_time:.2f}s | Total: {total_time:.2f}s]", file=sys.stderr)


if __name__ == "__main__":
    main()
