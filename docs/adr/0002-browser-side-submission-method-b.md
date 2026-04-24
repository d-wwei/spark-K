# ADR-0002: Browser-side `/prompt` submission ("method B") as default

- **Status**: Accepted (2026-04-24)
- **Context**: The skill can submit ComfyUI workflows via (A) direct curl from the agent's shell or (B) `browser eval fetch('/prompt')` from the user's browser pane. The UI's Job Queue, Media Assets thumbnails, and per-node progress bars depend on the task being routed to the browser's WebSocket `clientId`. Curl submissions use a different `client_id`, so the UI sees the task but cannot attribute it to the user's session, and progress doesn't render.
- **Decision**: Default to method B for all `/prompt` submissions. The agent reads `sessionStorage.getItem('clientId')` from the browser, includes it in the payload, and fires `fetch()` via `browser eval`. Method A is explicitly banned in the skill's red lines.
- **Consequences**:
  - ✅ User sees the same state the agent sees: queue position, sampler progress, saved images (supports red line #1)
  - ✅ Any user action in the UI (pause, cancel) applies to tasks the agent submitted
  - ❌ Requires browser pane to remain open and authenticated; if the user closes it, submissions stop
  - ❌ `browser eval` has a payload size ceiling (~2 MB in cmux); very large workflows must be uploaded separately
- **Alternatives considered**:
  - Method A (direct curl) — rejected: breaks user co-visibility, which is the skill's reason for existing
  - WebSocket-only submission — ComfyUI does not expose WS-based submit; `/prompt` is REST-only
  - MCP tool (`comfy_submit`) — future work; out of scope for skill layer
