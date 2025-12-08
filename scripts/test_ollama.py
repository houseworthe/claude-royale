#!/usr/bin/env python3
"""Test Ollama vision API with Qwen3-VL"""

import base64
import json
import sys
import time
import urllib.request

def test_ollama_vision(image_path, prompt="What type of screen is this: battle or menu? Answer one word."):
    # Read and encode image
    with open(image_path, 'rb') as f:
        img_b64 = base64.b64encode(f.read()).decode('utf-8')

    print(f"Image size: {len(img_b64)} bytes (base64)")

    # Build request
    payload = {
        "model": "qwen3-vl:4b",
        "prompt": prompt,
        "images": [img_b64],
        "stream": False,
        "options": {"num_predict": 500, "think": False}
    }

    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        'http://localhost:11434/api/generate',
        data=data,
        headers={'Content-Type': 'application/json'}
    )

    start = time.time()
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode('utf-8'))
            elapsed = time.time() - start
            print(f"Time: {elapsed:.2f}s")
            print(f"Response: {result.get('response', 'NO RESPONSE')}")
            print(f"Full result: {result}")
            return result
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    image = sys.argv[1] if len(sys.argv) > 1 else "/Users/ethanhouseworth/Documents/Personal-Projects/claude-royale/screenshots/current.png"
    prompt = sys.argv[2] if len(sys.argv) > 2 else "What type of screen is this: battle or menu? Answer one word."
    test_ollama_vision(image, prompt)
