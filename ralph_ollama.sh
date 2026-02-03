#!/bin/bash
set -euo pipefail

# -------- CONFIG --------
OLLAMA_BASE_URL="http://host.docker.internal:11434"
MODEL_NAME="kimi-k2.5:cloud"
ANTHROPIC_API_KEY=""
ANTHROPIC_AUTH_TOKEN="ollama"
# ------------------------

if [ $# -lt 1 ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

ITERATIONS="$1"

# Pre-flight checks
if ! command -v docker >/dev/null 2>&1; then
  echo "Error: docker not found in PATH."
  exit 1
fi

if [ ! -f "prd.json" ] || [ ! -f "progress.txt" ]; then
  echo "Error: missing prd.json or progress.txt in current directory."
  exit 1
fi

PROMPT=$(cat <<'EOF'
@prd.json @progress.txt

1. Find the highest-priority feature to work on and work only on that feature.
This should be the one YOU decide has the highest priority - not necessarily the first in the list.
2. Check that the types check via npm run typecheck and that the tests pass via npm run test.
3. Update the PRD with the work that was done.
4. Append your progress to the progress.txt file.
Use this to leave a note for the next person working in the codebase.
5. Make a git commit of that feature.

ONLY WORK ON A SINGLE FEATURE.

If, while implementing the feature, you notice the PRD is complete,
output exactly:
<promise>COMPLETE</promise>
EOF
)

for ((i=1; i<=ITERATIONS; i++)); do
  echo
  echo "========== Iteration $i / $ITERATIONS =========="

  result=$(docker sandbox run \
    -e ANTHROPIC_BASE_URL="$OLLAMA_BASE_URL" \
    -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
    -e ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN" \
    claude \
    --model "$MODEL_NAME" \
    --permission-mode acceptEdits \
    -p "$PROMPT" \
    2>&1 || true)

  echo "$result"

  if grep -q "<promise>COMPLETE</promise>" <<< "$result"; then
    echo "✅ PRD complete after $i iterations."
    if command -v tt >/dev/null 2>&1; then
      tt notify "CVM PRD complete after $i iterations"
    fi
    exit 0
  fi
done

echo "⚠️ Iterations finished without PRD completion."
