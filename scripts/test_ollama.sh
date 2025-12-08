#!/bin/bash
# Test Ollama vision API

IMAGE_PATH="${1:-/Users/ethanhouseworth/Documents/Personal-Projects/claude-royale/screenshots/current.png}"
PROMPT="${2:-Is this a battle screen or main menu? Answer one word: menu or battle}"

# Base64 encode image
IMG_B64=$(base64 -i "$IMAGE_PATH" | tr -d '\n')

# Call Ollama API
curl -s http://localhost:11434/api/generate \
  -d @- <<EOF | jq -r '.response'
{
  "model": "qwen3-vl:2b",
  "prompt": "$PROMPT",
  "images": ["$IMG_B64"],
  "stream": false,
  "options": {
    "num_predict": 20
  }
}
EOF
