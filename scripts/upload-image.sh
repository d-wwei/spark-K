#!/usr/bin/env bash
# upload-image.sh — correct-by-construction image upload to ComfyUI via /upload/image.
# Routes the file through Sentinel's per-user path resolution (which direct `cp` does NOT).
# Usage: upload-image.sh <local-path> [SURFACE_ID]
# Env: COMFY_HOST (default 172.22.20.115:8188), COMFY_COOKIE_JAR (default /tmp/spark-K-cookies.txt)
set -u

LOCAL="${1:-}"
SURFACE_ID="${2:-}"
HOST="${COMFY_HOST:-172.22.20.115:8188}"
JAR="${COMFY_COOKIE_JAR:-/tmp/spark-K-cookies.txt}"

if [[ -z "$LOCAL" || ! -f "$LOCAL" ]]; then
  echo "upload-image: file not found: $LOCAL" >&2
  exit 2
fi

BASENAME=$(basename "$LOCAL")

# Path A: if cookie jar exists (session did curl-login earlier), upload via curl — simpler, more reliable for large files
if [[ -f "$JAR" ]] && grep -q "jwt_token" "$JAR" 2>/dev/null; then
  RESP=$(/usr/bin/curl -s -b "$JAR" -X POST "http://${HOST}/upload/image" \
    -F "image=@${LOCAL}" \
    -F "overwrite=true" -w "\nHTTP=%{http_code}")
  HTTP=$(echo "$RESP" | tail -1 | cut -d= -f2)
  if [[ "$HTTP" == "200" ]]; then
    echo "upload-image: OK (via curl)"
    echo "$RESP" | head -1
    exit 0
  fi
  echo "upload-image: curl path failed (HTTP=$HTTP), falling back to browser" >&2
fi

# Path B: browser Blob upload (no shared cookie jar needed)
if [[ -z "$SURFACE_ID" ]]; then
  echo "upload-image: no cookie jar and no SURFACE_ID; cannot upload" >&2
  exit 1
fi

# Read file into base64, hand to browser, let it build a Blob
B64=$(base64 -i "$LOCAL" | tr -d '\n')
RESP=$(cmux browser --surface "$SURFACE_ID" eval "
(async function(){
  const b64 = '${B64}';
  const byteChars = atob(b64);
  const bytes = new Uint8Array(byteChars.length);
  for (let i = 0; i < byteChars.length; i++) bytes[i] = byteChars.charCodeAt(i);
  const blob = new Blob([bytes]);
  const fd = new FormData();
  fd.append('image', blob, '${BASENAME}');
  fd.append('overwrite', 'true');
  const r = await fetch('/upload/image', {method:'POST', body: fd, credentials:'include'});
  return JSON.stringify({status: r.status, body: await r.json()});
})()
" 2>&1)
echo "upload-image: $RESP"
echo "$RESP" | grep -q '"status":200' && exit 0 || exit 1
