#!/usr/bin/env bash
# check-setup.sh — verify spark-K setup is complete before a subcommand runs.
# Exits 0 if ready, 1 if not. Arguments: SURFACE_ID (cmux surface ref, e.g. "surface:36").
# In Chrome mode, pass "chrome" as SURFACE_ID.
set -u

SURFACE_ID="${1:-}"
HOST="${COMFY_HOST:-127.0.0.1:8188}"

if [[ -z "$SURFACE_ID" ]]; then
  echo "check-setup: SURFACE_ID required (cmux surface ref, or 'chrome')" >&2
  exit 2
fi

# 1. Host reachable
if ! /usr/bin/curl -s -m 3 -o /dev/null -w "%{http_code}" "http://${HOST}/login" | grep -q "200"; then
  echo "check-setup: ComfyUI not reachable at ${HOST}" >&2
  exit 1
fi

# 2. Browser has WS subscriber installed
if [[ "$SURFACE_ID" == "chrome" ]]; then
  INSTALLED=$(osascript -e 'tell application "Google Chrome" to execute active tab of front window javascript "window.__sparkK_installed === true"' 2>/dev/null)
else
  INSTALLED=$(cmux browser --surface "$SURFACE_ID" eval "window.__sparkK_installed === true" 2>/dev/null)
fi
if [[ "$INSTALLED" != *"true"* ]]; then
  echo "check-setup: WS subscriber not installed in $SURFACE_ID (expected window.__sparkK_installed === true)" >&2
  exit 1
fi

# 3. Auth probe: /api/queue must return 200 from the browser context (proves session cookie valid)
if [[ "$SURFACE_ID" == "chrome" ]]; then
  STATUS=$(osascript -e 'tell application "Google Chrome" to execute active tab of front window javascript "fetch(\"/api/queue\").then(r=>r.status)"' 2>/dev/null)
else
  STATUS=$(cmux browser --surface "$SURFACE_ID" eval "fetch('/api/queue').then(r=>r.status)" 2>/dev/null)
fi
if [[ "$STATUS" != *"200"* ]]; then
  echo "check-setup: /api/queue returned '$STATUS' from $SURFACE_ID (expected 200)" >&2
  exit 1
fi

echo "check-setup: OK"
exit 0
