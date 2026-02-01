#!/bin/bash
set -e

# Configuration for using Ollama with Claude Code CLI
# We bypass 'ollama launch' because it's interactive and doesn't handle passing flags to the CLI well.
# Instead, we configure the Claude CLI directly to talk to the local Ollama instance.

# Default configuration (Update these if your Ollama setup differs)
export ANTHROPIC_BASE_URL=http://localhost:11434
export ANTHROPIC_API_KEY=ollama   # Needed to bypass local key check

# IMPORTANT: CHANGE THE MODEL NAME HERE!
# Specify the model you have pulled in Ollama (e.g., qwen2.5-coder, gpt-oss:20b, llama3, etc.)
# If you don't specify this, the CLI might try to use a default specific-to-Anthropic model which fails locally.
MODEL_NAME="qwen2.5-coder:latest" 

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

# Check if 'claude' command is available
if ! command -v claude &> /dev/null; then
  echo "Error: 'claude' command not found."
  echo "Please ensure you have installed the Claude Code CLI (e.g. via 'npm install -g @anthropic-ai/claude-code')."
  exit 1
fi

for ((i=1; i<=$1; i++)); do
  echo "Iteration $i"
  echo "--------------------------------"
  
  # Construct the prompt with files if they exist
  CONTEXT=""
  if [ -f "prd.json" ]; then
      CONTEXT="$CONTEXT\n\n--- prd.json ---\n$(cat prd.json)"
  fi
  if [ -f "progress.txt" ]; then
      CONTEXT="$CONTEXT\n\n--- progress.txt ---\n$(cat progress.txt)"
  fi
  
  PROMPT="$CONTEXT
1. Find the highest-priority feature to work on and work only on that feature. \
This should be the one YOU decide has the highest priority - not necessarily the first in the list. \
2. Check that the types check via npm run typecheck and that the tests pass via npm run test. \
3. Update the PRD with the work that was done. \
4. Append your progress to the progress.txt file. \
Use this to leave a note for the next person working in the codebase. \
5. Make a git commit of that feature. \
ONLY WORK ON A SINGLE FEATURE. \
If, while implementing the feature, you notice the PRD is complete, output <promise>COMPLETE</promise>. \
"

  # Run Claude CLI
  # We pass the --model flag to specify the Ollama model
  
  result=$(claude --model "$MODEL_NAME" --permission-mode acceptEdits -p "$PROMPT")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete, exiting."
    if command -v tt &> /dev/null; then
        tt notify "CVM PRD complete after $i iterations"
    fi
    exit 0
  fi
done
