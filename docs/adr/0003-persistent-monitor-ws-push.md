# ADR-0003: Persistent Monitor + browser-side WS subscriber for progress push

- **Status**: Accepted (2026-04-24)
- **Context**: The agent needs to learn about task completion / errors without the user asking. Three candidate signal sources: (1) poll `/api/queue` + `/history` every N seconds, (2) tail ComfyUI server log, (3) subscribe to ComfyUI `/ws` inside the browser and expose events via a global array. Options (1) and (2) miss step-level events that `/ws` emits (per-node progress, `executed` with output filenames). Option (3) also runs in the browser that the user watches, so events are consistent across both sides.
- **Decision**: Inject a WS subscriber into the browser that stores filtered events in `window.__sparkK_events`. Launch a persistent Monitor task that polls the array every 2 seconds and prints only significant events (`execution_error`, `execution_success`, `executed` with images, `execution_interrupted`, `status` when queue empties). Each stdout line from the Monitor becomes one chat notification.
- **Consequences**:
  - ✅ User and agent see the same event stream (supports acceptance criterion #4)
  - ✅ Lightweight — one JS subscriber + one shell loop, no new daemons
  - ✅ Filter excludes high-frequency `progress` and `executing` events, so Monitor stays below the "too noisy → auto-stop" threshold
  - ❌ Page reload drops `__sparkK_events`; subscriber must be re-injected. Skill's `check-setup.sh` detects this.
  - ❌ Requires two active subscribers to `/ws` (the UI itself + spark-K's injected one); Sentinel doesn't rate-limit WS connections today, but this is an untested assumption
- **Alternatives considered**:
  - Polling `/api/queue` — rejected: lost patch-level granularity, already-known server.py bug around queue item slicing
  - Tail server log via `tail -F` — rejected: SUPIR sampler is silent on stderr (observed 2026-04-24), so 50%+ of sampling duration is invisible
  - Electron-level IPC hooks in cmux — out of scope, platform-specific
