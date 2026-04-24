# Domain Research — ComfyUI Programmatic Automation

**Domain**: ComfyUI API / workflow automation clients. spark-K is one such automation, specialized for browser-co-visible co-execution with Claude agents.

## Sources (≥5 required)

| # | Source | Key Finding | Implication for spark-K |
|---|--------|-------------|-------------------------|
| 1 | [Runflow Developer Guide](https://www.runflow.io/blog/comfyui-api-developer-guide) | Canonical Python client: `connect_ws → upload → queue → wait → fetch_outputs`. Uses `/view?filename=X&subfolder=Y&type=output` to download output bytes | spark-K skips `/view` step—only prints filesystem path. For distributable skills, should offer the `/view` fetch path too so Claude can receive image bytes for inline display |
| 2 | [ViewComfy Production Guide](https://www.viewcomfy.com/blog/building-a-production-ready-comfyui-api) | Separates `establish_connection()`, `update_workflow(params)`, `upload_image`, `queue_prompt`, `track_progress`, `get_history`, `get_image`. Strict separation of concerns | spark-K collapses these into one "method B" submission blob. Better layering: one function per API concern |
| 3 | [WebSockets & ComfyUI (DEV)](https://dev.to/worldlinetech/websockets-comfyui-building-interactive-ai-applications-1j1g) | WS event types: `status`, `executing` (with `node: null` = done for prompt_id), `progress`, `executed`. Real-time display in Jupyter | spark-K already filters on similar types; confirms we're not missing critical events. `executing` with `node: null` + matching prompt_id is the canonical "done" signal—spark-K uses `execution_success` which may not always fire (version-dependent) |
| 4 | [DevLog 20250710 ComfyUI API](https://dev.to/methodox/devlog-20250710-comfyui-api-1mi0) | ComfyUI is API-first: `/ws` + `/prompt` are primary primitives; UI is just one client. API Nodes extend via HTTP | Validates spark-K's direct API usage over UI automation. No need to fear breaking when ComfyUI UI changes |
| 5 | [ComfyUI Official Docs — Routes](https://docs.comfy.org/development/comfyui-server/comms_routes) | `/prompt` returns `{prompt_id, number}` or `{error, node_errors}`. `node_errors` dict keyed by node ID | spark-K should surface `node_errors` to user when present, not just fail silently. Current skill does print but only top-level error |
| 6 | [Comfy Cloud API](https://docs.comfy.org/development/cloud/overview) | Commercial path: API Key + `/api/prompt` + `/api/job/{id}/status` + parallel submission. Native concurrency via independent prompts | Validates that **queue-and-wait pattern with server-side parallelism** is the scaling model, not client threads. spark-K could extend to "submit N, wait N" via loop |
| 7 | [SamratBarai/ComfyAPI GitHub](https://github.com/SamratBarai/ComfyAPI) | Reference Python client. Small, focused, no auth wrapper (assumes local dev) | Useful as transplant candidate for spark-K's "non-browser" fallback (pure-python submitter via cookie jar) |
| 8 | [9elements Hosting Guide](https://9elements.com/blog/hosting-a-comfyui-workflow-via-api/) | **Find nodes by `class_type` iteration, not hard-coded ID**: `nodes = {id: n['class_type'] for id, n in wf.items()}; ksampler_id = [id for id, t in nodes.items() if t == 'KSampler'][0]` | ⚠️ Biggest gap: spark-K hard-codes node IDs (`'5'`, `'3'`) in workflow templates. If user re-saves workflow in UI, IDs may reshuffle. **Should iterate by class_type** |

## Expert-vs-spark-K Workflow Mapping

| Phase | Expert Pattern (common across sources) | spark-K Current | Gap? |
|-------|---------------------------------------|-----------------|------|
| Auth | Skip (assume local/trusted) OR API key | Sentinel JWT via Keychain | spark-K is stricter (good for shared LAN) — no gap |
| WS Connect | Connect with `clientId`, retain handle | Inject listener in browser, drain buffer | Different approach; spark-K advantage: user co-visible |
| Image Upload | `/upload/image` multipart | `/upload/image` multipart (noted) but implementation defers to browser Blob or curl | **Gap**: skill doesn't ship working upload code, just hints. First-time user will hit CORS |
| Workflow mutation | Find node by `class_type`, mutate inputs | Hard-code node ID + `.replace()` on `{{PLACEHOLDER}}` strings | **Gap**: fragile to workflow re-save |
| Submission | `POST /prompt {prompt, client_id}` | Via browser.eval with sessionStorage clientId | Valid; spark-K's unique value |
| Track | WS `executing` with `node: null` = done | `execution_success` event | **Gap**: less canonical; may miss old-version completions |
| Error handling | Surface `node_errors` dict | Print top-level error only | **Gap**: user doesn't see which node failed |
| Output retrieval | `GET /history/{id}` → `/view?filename=X` | Print filesystem path only | **Gap**: can't work on remote ComfyUI (over Tailscale/LAN from different host) |

## Cross-Disciplinary Scan

- **Playwright/Puppeteer** (browser automation): spark-K's "inject JS + query variable" pattern mirrors Playwright's `page.evaluate()`. Accepted best practice.
- **OAuth PKCE flows** (web auth): spark-K's "login in browser, extract token from cookie" is the web-app OAuth handoff pattern. Standard, safe.
- **CLI wrappers over web APIs** (GitHub CLI, gh): convention of "semantic verb + named resource" (e.g. `gh pr create`). spark-K's `/spark-K upscale <image>` follows this. Good.

## Domain Best-Practice Summary

1. **Prefer class_type iteration over node-ID hard-coding** (source #8) — highest-leverage fix for template robustness
2. **Use `/view` for output retrieval** (source #1) — necessary for remote ComfyUI scenarios
3. **Surface `node_errors`** (source #5) — user actionability on validation failures
4. **Match on `executing + node: null`** (source #3) — canonical completion signal
5. **Separate concerns into discrete functions/sections** (source #2) — readability and testability
