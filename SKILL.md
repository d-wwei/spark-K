---
name: spark-K
description: Open a local ComfyUI (with ComfyUI-Sentinel auth) in an integrated browser pane, log in using credentials from the OS credential store, install a WebSocket progress pump, and from then on submit every workflow through the browser's JS context so the ComfyUI UI shows live queue state, per-node progress, and output thumbnails. Use when the user invokes `/spark-K` or a subcommand `/spark-K upscale|fast-upscale|t2i <args>`, or asks to "open ComfyUI", "log into ComfyUI", "run a workflow with live progress", or "submit a workflow so I can see it in the UI".
scope: darwin
subcommands: upscale, fast-upscale, t2i
---

# spark-K — ComfyUI Co-Execution Router

## Stance

Think like a browser-native operator of a local diffusion server. Every task must be visible, co-auditable, and interruptible by the user in real time. Constraints on the agent are also constraints on what the user might accidentally ask: refuse silent back-channel submissions; push progress outward; prefer approaches where the user can see the same state the agent sees.

## Red Lines

These are mechanically checkable. Violations in skill output or transcripts MUST be flagged as failures.

1. **No `/prompt` submission without `client_id: sessionStorage.getItem('clientId')`** from the browser pane. Check: grep transcripts for `POST /prompt` — every occurrence has the sessionStorage-derived client_id in the same payload.
2. **No plaintext credential in any committed file or transcript**. Check: grep for password patterns (`password.*=.*"[A-Za-z0-9#]`) in skill files and transcripts.
3. **No `cp` of an image into `~/ComfyUI/input/` or subfolders**. Check: grep for `cp .* ComfyUI/input`. Correct path: call `scripts/upload-image.sh <file>`.
4. **No subcommand executes before setup is verified** (`window.__sparkK_installed === true` + `/api/queue` returns 200). Check: every subcommand branch calls `scripts/check-setup.sh` first and halts on non-zero exit.
5. **No login flow uses `curl` for `POST /login`**. Cookie must land in the browser jar, not curl's. Check: grep for `curl.* POST .* /login` — zero occurrences expected.
6. **No edit of `~/ComfyUI/server.py` without an ADR**. The `_remove_sensitive_from_queue` patch (known-issues.md) requires `docs/adr/` entry before being applied.

## Acceptance Criteria

User-observable pass/fail for a successful skill run:

1. **Browser pane exists and shows ComfyUI main UI at `http://172.22.20.115:8188/`** (not login page). The user sees their workflow graph, not a form.
2. **`/api/queue` from the browser returns HTTP 200 with JSON body `{queue_running, queue_pending}`**. The agent prints the raw response as evidence.
3. **`window.__sparkK_installed === true` in the browser context** AND a persistent Monitor task ID is reported back to the user. Without both, progress push is not actually armed.
4. **Every subsequent subcommand run emits at least one `🖼  SAVED` / `❌ ERROR` / `🏁 QUEUE EMPTY` push notification** per task lifecycle. Silent completion is a regression.

## Dispatch Table

| User invocation | Load reference | Summary |
|-----------------|----------------|---------|
| `/spark-K` (no args) | `references/setup.md` + `references/progress-pump.md` | Login + inject WS + arm Monitor |
| `/spark-K upscale <img>` | `references/subcommand-upscale.md` | UltraSharp 4x + SUPIR (20+ min) |
| `/spark-K fast-upscale <img>` | `references/subcommand-fast-upscale.md` | UltraSharp 4x only (~1–2 s) |
| `/spark-K t2i "<prompt>"` | `references/subcommand-t2i.md` | Flux2 text-to-image + SUPIR (⚠️ untested) |

Every subcommand MUST first run the setup + progress pump if not already done.

## Scope & Prerequisites

- macOS (Darwin). Non-Darwin execution is out of scope; skill will refuse with a clear message.
- ComfyUI with [ComfyUI-Sentinel](https://github.com/biggPP/ComfyUI-Sentinel) auth middleware, running at `172.22.20.115:8188`.
- Either cmux (browser-pane host with `browser eval` / `browser cookies set` / `new-split --type browser`) or Google Chrome with "Allow JavaScript from Apple Events" enabled. Detection: `$CMUX_WORKSPACE_ID` set and `cmux` on PATH → cmux; otherwise Chrome.

## References Table

| File | Load when | Target words |
|------|-----------|-------------|
| `references/setup.md` | User runs `/spark-K` without args or first subcommand | ≤ 800 |
| `references/progress-pump.md` | Setup phase, WS injection + Monitor launch | ≤ 600 |
| `references/method-b-template.md` | Any `/prompt` submission | ≤ 300 |
| `references/image-upload.md` | Subcommands that take an image argument | ≤ 300 |
| `references/subcommand-upscale.md` | `/spark-K upscale` invocation | ≤ 300 |
| `references/subcommand-fast-upscale.md` | `/spark-K fast-upscale` invocation | ≤ 200 |
| `references/subcommand-t2i.md` | `/spark-K t2i` invocation | ≤ 400 |
| `references/known-issues.md` | Any failure path / unexpected server error | ≤ 400 |
| `docs/adr/*.md` | Design rationale lookups | n/a |

Scripts directory (`scripts/`) contains: `check-setup.sh`, `upload-image.sh`, `lint-submission.sh`, `fill-template.py`, `fetch-output.sh`. These are invoked from reference files, not from this router.

## Cleanup

```bash
security delete-generic-password -s "spark-K-comfyui" -a "Admin"
rm -rf ~/.claude/skills/spark-K
# Also stop any running Monitor task via TaskStop.
```
