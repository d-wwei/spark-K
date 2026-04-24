# spark-K

A Claude Code skill that one-clicks ComfyUI open + auto-login on your LAN, with browser-side prompt submission so the UI shows live progress and results.

## What it does

Invoke `/spark-K` inside Claude Code and the agent will:

1. **Detect environment** — cmux (uses built-in browser pane, splits current workspace) or bare Chrome (uses `chrome-control` skill).
2. **Open ComfyUI** at `http://127.0.0.1:8188` (Sentinel login page).
3. **Auto-login** as `Admin` using a password stored in macOS Keychain. First run will prompt and save it.
4. **Verify** `/api/queue` returns 200.
5. **Declare "method B"** for the session — all subsequent prompt submissions go through the browser's JS context (`cmux browser eval` or Chrome AppleScript) with the browser's own `sessionStorage.clientId`. This makes the tasks visible in ComfyUI's Job Queue panel and results land in Media Assets with thumbnails — you can follow along and intervene.
6. **Install a progress pump** — injects a WebSocket subscriber into the browser (`window.__sparkK_events`) and starts a persistent Monitor that polls every 2 s and proactively pushes completion / error / saved-image / queue-empty events as chat notifications. No polling from the user — Claude tells you when the job is done.

## Why this exists

When Claude submits prompts via plain `curl`, the `client_id` is not the browser's, so the UI sees the jobs but treats them as anonymous API traffic — no Media Assets, no per-node progress bars, no collaboration. Method B closes that gap by running the submission inside the browser where your real session lives.

## Install

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/d-wwei/spark-K.git ~/.claude/skills/spark-K
```

Then restart Claude Code (or trigger skill discovery). After that `/spark-K` is a recognized command.

## Prerequisites

- macOS (Keychain + AppleScript dependencies)
- ComfyUI with [ComfyUI-Sentinel](https://github.com/biggPP/ComfyUI-Sentinel) auth middleware
- Either:
  - cmux (for built-in browser pane), or
  - Chrome with "View → Developer → Allow JavaScript from Apple Events" enabled (for `chrome-control` fallback)

## Configuration

First `/spark-K` run stores your Sentinel password in Keychain:

```
service: spark-K-comfyui
account: Admin
```

To change / remove:

```bash
# Update
security add-generic-password -s spark-K-comfyui -a Admin -w "NEW_PASSWORD" -U

# Delete
security delete-generic-password -s spark-K-comfyui -a Admin
```

## Known gotchas encoded into the skill

These were found the hard way while building this:

- **ComfyUI `server.py:59` bug** — `_remove_sensitive_from_queue` assumes tuples but ComfyUI-Sentinel wraps queue items as dicts, making `/api/queue` return 500. The skill detects this and can prompt you to patch.
- **Per-user input isolation** — do not `cp` images into `~/ComfyUI/input/`. Must go through `/upload/image` (or equivalent browser-side upload) so Sentinel routes the file into `input/<user-uuid>/`.
- **SUPIR sampler is silent** — during the SUPIR_Upscale diffusion step the UI progress bar parks at 50% for 10–20 min with no WebSocket progress events. The skill notes not to confuse this with a stuck job.

## Limitations

- macOS only. Chrome CDP on Windows path isn't implemented yet.
- Hardcoded `Admin` username. If you have multi-user Sentinel the skill needs a `--user` arg.
- Assumes ComfyUI on `127.0.0.1:8188`. Custom host/port requires editing the skill.

## License

MIT
