#!/usr/bin/env bash

INPUT=$(cat) || exit 1

COMMAND=$(echo "$INPUT" | jq -e -r '.tool_input.command' 2>/dev/null) || exit 1
CWD=$(echo "$INPUT" | jq -e -r '.cwd' 2>/dev/null) || exit 1

if [[ "$COMMAND" == "null" ]] || [[ -z "$COMMAND" ]]; then
  exit 0
fi

if [[ "$CWD" == "null" ]] || [[ -z "$CWD" ]]; then
  exit 0
fi

# Only intercept git commit commands
if ! echo "$COMMAND" | grep -q 'git commit'; then
  exit 0
fi

# Get list of staged files
STAGED_FILES=$(cd "$CWD" && git diff --cached --name-only 2>/dev/null)
if [[ -z "$STAGED_FILES" ]]; then
  exit 0
fi

# Extract unique app directories from staged files
AFFECTED_APPS=$(echo "$STAGED_FILES" | grep -oE '^apps/[^/]+' | sort -u || true)

if [[ -z "$AFFECTED_APPS" ]]; then
  # No app files staged, allow commit to proceed
  jq -n '{"suppressOutput": true}'
  exit 0
fi

# Find the umbrella root (where apps/ directory is)
find_umbrella_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if [[ -d "$dir/apps" ]]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  return 1
}

UMBRELLA_ROOT=$(find_umbrella_root "$CWD")
if [[ -z "$UMBRELLA_ROOT" ]]; then
  exit 0
fi

# Run precommit for each affected app
FAILED_APPS=()
ERRORS=""
for APP_PATH in $AFFECTED_APPS; do
  APP_DIR="$UMBRELLA_ROOT/$APP_PATH"
  APP_NAME=$(basename "$APP_PATH")

  if [[ -f "$APP_DIR/mix.exs" ]]; then
    OUTPUT=$(cd "$APP_DIR" && mix precommit 2>&1)
    EXIT_CODE=$?

    if [[ $EXIT_CODE -ne 0 ]]; then
      FAILED_APPS+=("$APP_NAME")
      ERRORS="${ERRORS}[ERROR] Precommit failed for ${APP_NAME}:\n${OUTPUT}\n\n"
    fi
  fi
done

# If any app failed, block the commit
if [[ ${#FAILED_APPS[@]} -gt 0 ]]; then
  ERROR_MSG="Precommit checks failed for: ${FAILED_APPS[*]}\n\n${ERRORS}Fix these issues before committing."

  jq -n \
    --arg reason "$ERROR_MSG" \
    --arg msg "Commit blocked: precommit validation failed" \
    '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": $reason
      },
      "systemMessage": $msg
    }'
  exit 0
fi

jq -n '{"suppressOutput": true}'
exit 0
