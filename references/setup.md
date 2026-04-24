# Setup (no-args `/spark-K`)

Bring the skill from cold start to "ready for submissions." Load this reference when `/spark-K` is invoked without arguments, or when a subcommand detects that setup has not run.

## Step 1 — Reachability probe

```bash
/usr/bin/curl -s -m 3 -o /dev/null -w "%{http_code}" http://172.22.20.115:8188/login
```

If not `200`, stop. Tell the user ComfyUI is not running. Do not proceed.

## Step 2 — Retrieve credentials

```bash
USERNAME="Admin"
PASSWORD=$(security find-generic-password -s "spark-K-comfyui" -a "$USERNAME" -w 2>/dev/null)
```

Empty? Ask the user for the password via the agent's question tool, then write it:

```bash
security add-generic-password -s "spark-K-comfyui" -a "Admin" -w "$PASSWORD" -U
```

Do not echo or log the password. Do not put it in any tool parameter shown back to the user.

## Step 3 — Detect host environment

```bash
if [[ -n "$CMUX_WORKSPACE_ID" ]] && command -v cmux >/dev/null 2>&1; then
  MODE=cmux
else
  MODE=chrome
fi
```

## Step 4 — Open the browser pane

### cmux branch

Look for an existing ComfyUI surface first:

```bash
SURFACE_ID=$(cmux tree --all 2>&1 | grep -E "browser.*(172\.22\.20\.115|127\.0\.0\.1):8188" | grep -oE "surface:[0-9]+" | tail -1)
```

If empty, create one:

```bash
cmux new-split right --type browser --url "http://172.22.20.115:8188/login"
sleep 2
SURFACE_ID=$(cmux tree --all 2>&1 | grep -E "browser.*(172\.22\.20\.115|127\.0\.0\.1):8188" | grep -oE "surface:[0-9]+" | tail -1)
```

### chrome branch

Run the `chrome-control` skill's preflight first. Then:

```bash
osascript -e 'tell application "Google Chrome" to tell front window to make new tab with properties {URL:"http://172.22.20.115:8188/login"}'
osascript -e 'tell application "Google Chrome" to activate'
sleep 2
```

`SURFACE_ID=chrome` (sentinel value for this branch).

## Step 5 — Log in from inside the browser

Submission uses browser `fetch('/login')` so the `jwt_token` cookie lands in the browser jar (HttpOnly, JS cannot read back; but `credentials: 'include'` future requests will carry it). **Do not use curl for this step** (red line #5).

```js
(async function(){
  const fd = new FormData();
  fd.append('username', 'Admin');
  fd.append('password', PASSWORD_AS_JSON);  // JSON-escape via python -c 'import json,sys;print(json.dumps(sys.stdin.read()))'
  const r = await fetch('/login', {method:'POST', body: fd, credentials:'include'});
  return JSON.stringify({status: r.status, ok: r.ok});
})()
```

Expect `{status:200, ok:true}`. Navigate to `/` after.

## Step 6 — Install the WebSocket subscriber

Load `progress-pump.md` and perform step 8.1.

## Step 7 — Start the persistent Monitor

Load `progress-pump.md` and perform step 8.2. Record the returned `task_id`.

## Step 8 — Report back

Tell the user:

- `SURFACE_ID`: the browser ref they can interact with
- Monitor task id (for `TaskStop` later)
- Confirmation that `/api/queue` returned 200 from inside the browser context
