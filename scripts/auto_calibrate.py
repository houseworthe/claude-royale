#!/usr/bin/env python3
"""
Automated coordinate calibration for BlueStacks/Clash Royale.

This script probes a single point: moves cursor there, takes screenshot,
and attempts to find the cursor position in the screenshot.

Usage: python3 auto_calibrate.py <click_x> <click_y> <output_file>

The output file will contain JSON with:
- click_point: [x, y] - where we told cliclick to move
- screenshot_pixel: [x, y] - where cursor appeared in screenshot (or null if not found)
"""

import sys
import subprocess
import json
import os
import time
from pathlib import Path

def move_cursor(x: int, y: int) -> bool:
    """Move cursor to position using cliclick."""
    result = subprocess.run(['cliclick', 'm:{},{}'.format(x, y)], capture_output=True)
    return result.returncode == 0

def take_screenshot(output_path: str) -> bool:
    """Take screenshot with cursor visible."""
    result = subprocess.run(['screencapture', '-C', '-x', output_path], capture_output=True)
    return result.returncode == 0

def find_cursor_in_image(image_path: str) -> tuple[int, int] | None:
    """
    Find the cursor position in a screenshot.

    The macOS cursor is typically a black arrow with white outline.
    We'll look for the characteristic pattern.

    Returns (x, y) pixel position or None if not found.
    """
    try:
        from PIL import Image
        import numpy as np
    except ImportError:
        # Fallback: try to use sips to get basic info
        # This won't find cursor but at least confirms image exists
        return None

    img = Image.open(image_path)
    img_array = np.array(img)

    # The cursor is typically black (0,0,0) with white outline (255,255,255)
    # Look for a distinctive pattern: black pixel surrounded by white

    height, width = img_array.shape[:2]

    # Scan for cursor pattern (simplified: look for small black region)
    # The arrow cursor tip is typically around 1-3 pixels

    # Convert to grayscale for easier processing
    if len(img_array.shape) == 3:
        gray = np.mean(img_array[:, :, :3], axis=2)
    else:
        gray = img_array

    # Look for the cursor pattern - black tip with white outline
    # This is a simplified heuristic
    for y in range(1, height - 1):
        for x in range(1, width - 1):
            # Check if this pixel is very dark (potential cursor tip)
            if gray[y, x] < 30:
                # Check if surrounded by lighter pixels (white outline)
                neighbors = [
                    gray[y-1, x], gray[y+1, x],
                    gray[y, x-1], gray[y, x+1]
                ]
                if sum(1 for n in neighbors if n > 200) >= 2:
                    # Potential cursor found
                    # Verify it's not just random dark pixel by checking pattern
                    # Cursor arrow points down-right, so check that pattern
                    if y + 5 < height and x + 5 < width:
                        # Check for arrow shape going down-right
                        arrow_pixels = [
                            gray[y+1, x+1] < 50,
                            gray[y+2, x+1] < 50 or gray[y+1, x+2] < 50,
                        ]
                        if sum(arrow_pixels) >= 1:
                            return (x, y)

    return None

def find_cursor_simple(image_path: str) -> tuple[int, int] | None:
    """
    Find the macOS arrow cursor in screenshot.

    The macOS cursor is a small white arrow with black outline,
    approximately 12x18 pixels. It has a distinctive triangular shape
    pointing up and slightly left.
    """
    try:
        from PIL import Image
        import numpy as np
    except ImportError:
        return None

    img = Image.open(image_path)
    img_array = np.array(img)

    height, width = img_array.shape[:2]

    # The macOS cursor is small (about 12x18 pixels)
    # It's white/light gray with a black 1px outline
    # The tip points up-left

    # Strategy: Look for the cursor's distinctive black outline pattern
    # The cursor tip is a single black pixel at top, expanding downward

    candidates = []

    # Scan the image looking for cursor-like patterns
    # Focus on finding the black outline first (more distinctive)
    for y in range(5, height - 20):
        for x in range(5, width - 15):
            # Look for potential cursor tip (black pixel with specific pattern below)
            pixel = img_array[y, x]

            # Check if this is a dark pixel (potential cursor outline)
            if pixel[0] < 50 and pixel[1] < 50 and pixel[2] < 50:
                # Check for cursor shape:
                # - Row 0: single black at tip
                # - Row 1-2: black on edges, white in middle
                # - Continues expanding downward

                score = 0

                # Check for white pixel to the right and below (cursor body)
                if x + 1 < width and y + 1 < height:
                    right = img_array[y, x + 1]
                    below = img_array[y + 1, x]
                    below_right = img_array[y + 1, x + 1]

                    # The cursor body should be white/light
                    if right[0] > 200 and right[1] > 200 and right[2] > 200:
                        score += 3
                    if below_right[0] > 200 and below_right[1] > 200 and below_right[2] > 200:
                        score += 3

                # Check pattern expands correctly (cursor gets wider going down)
                if y + 5 < height and x + 3 < width:
                    # 5 rows down, cursor should be about 4-5 pixels wide
                    row5 = img_array[y + 5, x:x + 5]
                    white_in_row = sum(1 for p in row5 if p[0] > 200 and p[1] > 200 and p[2] > 200)
                    black_in_row = sum(1 for p in row5 if p[0] < 50 and p[1] < 50 and p[2] < 50)
                    if white_in_row >= 2 and black_in_row >= 1:
                        score += 2

                # The cursor should NOT be in a large white area (that's likely game UI)
                # Check surrounding 30x30 area isn't mostly white
                region_y_start = max(0, y - 10)
                region_y_end = min(height, y + 20)
                region_x_start = max(0, x - 10)
                region_x_end = min(width, x + 20)
                region = img_array[region_y_start:region_y_end, region_x_start:region_x_end]

                # Count white pixels in region
                white_mask = (region[:,:,0] > 240) & (region[:,:,1] > 240) & (region[:,:,2] > 240)
                white_ratio = np.sum(white_mask) / white_mask.size

                # If region is mostly white (>50%), it's probably UI not cursor
                if white_ratio > 0.5:
                    score -= 10

                # Cursor is more likely to be in dark/black areas (empty space)
                black_mask = (region[:,:,0] < 30) & (region[:,:,1] < 30) & (region[:,:,2] < 30)
                black_ratio = np.sum(black_mask) / black_mask.size
                if black_ratio > 0.3:
                    score += 3

                if score >= 5:
                    candidates.append((x, y, score))

    if candidates:
        # Return the candidate with highest score
        best = max(candidates, key=lambda c: c[2])
        return (best[0], best[1])

    return None

def main():
    if len(sys.argv) != 4:
        print("Usage: python3 auto_calibrate.py <click_x> <click_y> <output_file>")
        sys.exit(1)

    click_x = int(sys.argv[1])
    click_y = int(sys.argv[2])
    output_file = sys.argv[3]

    # Create temp screenshot path
    screenshot_path = f"/tmp/calibrate_{click_x}_{click_y}.png"

    # Move cursor
    if not move_cursor(click_x, click_y):
        result = {"click_point": [click_x, click_y], "screenshot_pixel": None, "error": "Failed to move cursor"}
        with open(output_file, 'w') as f:
            json.dump(result, f)
        sys.exit(1)

    # Small delay for cursor to settle
    time.sleep(0.1)

    # Take screenshot
    if not take_screenshot(screenshot_path):
        result = {"click_point": [click_x, click_y], "screenshot_pixel": None, "error": "Failed to take screenshot"}
        with open(output_file, 'w') as f:
            json.dump(result, f)
        sys.exit(1)

    # Find cursor in screenshot
    cursor_pos = find_cursor_simple(screenshot_path)

    if cursor_pos is None:
        cursor_pos = find_cursor_in_image(screenshot_path)

    result = {
        "click_point": [click_x, click_y],
        "screenshot_pixel": list(cursor_pos) if cursor_pos else None,
        "screenshot_path": screenshot_path
    }

    with open(output_file, 'w') as f:
        json.dump(result, f, indent=2)

    # Print for immediate feedback
    print(json.dumps(result))

if __name__ == "__main__":
    main()
