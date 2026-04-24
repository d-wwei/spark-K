#!/usr/bin/env bash
# lint-submission.sh — scan files or transcripts for red line violations around /prompt submission.
# Usage: lint-submission.sh <path-or-glob>
# Red lines enforced (see SKILL.md):
#   #1 No POST /prompt without client_id: sessionStorage.getItem('clientId')
#   #2 No plaintext credentials
#   #3 No `cp` of images into ComfyUI/input/
#   #5 No curl POST /login
set -u

TARGETS="${*:-.}"
FAIL=0

check() {
  local pattern="$1"
  local description="$2"
  local hits
  hits=$(grep -rnE "$pattern" $TARGETS 2>/dev/null | grep -v "diagnosis/\|scripts/lint-submission.sh" || true)
  if [[ -n "$hits" ]]; then
    echo "❌ $description"
    echo "$hits" | head -5 | sed 's/^/   /'
    FAIL=1
  fi
}

# Red line #1: /prompt without clientId
# Accept: any POST to /prompt must have "client_id" AND "sessionStorage" within the same 10-line window.
# Heuristic: find lines with `POST.*prompt` or `fetch.*prompt`, then grep 10 lines after for clientId reference.
PROMPT_HITS=$(grep -rnE "fetch\s*\(\s*['\"]\S*/prompt|POST\s+\S*/prompt" $TARGETS 2>/dev/null | grep -v "diagnosis/\|scripts/lint" || true)
while IFS= read -r hit; do
  [[ -z "$hit" ]] && continue
  file=$(echo "$hit" | cut -d: -f1)
  line=$(echo "$hit" | cut -d: -f2)
  # Grab 10 lines after the hit and look for clientId mention
  window=$(sed -n "${line},$((line+10))p" "$file" 2>/dev/null)
  if ! echo "$window" | grep -qE "sessionStorage\.getItem\(['\"]clientId['\"]\)|client_id.*__sparkK_clientId"; then
    echo "❌ /prompt submission missing browser sessionStorage.clientId at $file:$line"
    FAIL=1
  fi
done <<< "$PROMPT_HITS"

# Red line #2: plaintext password
check 'password[^a-z]{0,5}=[^$"]{0,5}["'\''][A-Za-z0-9][A-Za-z0-9#@!$%^&*]{5,}' \
  "Plaintext credential pattern found"

# Red line #3: cp to ComfyUI/input
check 'cp\s+[^|&;]+ComfyUI/input/' \
  "Direct cp to ComfyUI/input/ (use scripts/upload-image.sh)"

# Red line #5: curl POST /login
check "curl[^|]*-X\s+POST[^|]*/login|curl[^|]*-F\s+['\"]?password[^|]*/login" \
  "curl POST /login (login must happen from browser context)"

if [[ $FAIL -eq 0 ]]; then
  echo "✅ lint-submission: no violations"
fi
exit $FAIL
