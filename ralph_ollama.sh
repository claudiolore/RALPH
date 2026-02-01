#!/bin/bash
set -e

# Configuration for Ollama
# We point to the host machine's Ollama instance from within the Docker container.
# On Windows/Mac/WSL, host.docker.internal resolves to the host.
# Ensure your Ollama (or proxy) is listening and accepts Anthropic-style requests if using the Claude CLI.
OLLAMA_BASE_URL="http://host.docker.internal:11434"
# Specify the model you have pulled in Ollama
MODEL_NAME="qwen2.5-coder:latest"

if [ -z "$1" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

for ((i=1; i<=$1; i++)); do
  echo "Iteration $i"
  echo "--------------------------------"
  
  # Run Claude in a sandbox, pointing it to the local Ollama instance
  result=$(docker sandbox run \
    -e ANTHROPIC_BASE_URL="$OLLAMA_BASE_URL" \
    -e ANTHROPIC_API_KEY="ollama" \
    claude \
    --model "$MODEL_NAME" \
    --permission-mode acceptEdits \
    -p "@prd.json @progress.txt \
1. Find the highest-priority feature to work on and work only on that feature. \
This should be the one YOU decide has the highest priority - not necessarily the first in the list. \
2. Check that the types check via npm run typecheck and that the tests pass via npm run test. \
3. Update the PRD with the work that was done. \
4. Append your progress to the progress.txt file. \
Use this to leave a note for the next person working in the codebase. \
5. Make a git commit of that feature. \
ONLY WORK ON A SINGLE FEATURE. \
If, while implementing the feature, you notice the PRD is complete, output <promise>COMPLETE</promise>. \
")

  echo "$result"

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo "PRD complete, exiting."
    tt notify "CVM PRD complete after $i iterations"
    exit 0
  fi
done
