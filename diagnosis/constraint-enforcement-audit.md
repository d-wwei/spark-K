# Constraint Enforcement Audit — spark-K

## Inventory of Implicit Constraints (Current SKILL.md has no explicit "Red Lines" section)

Extracted from prose / "基线假设" / "已知坑" / step descriptions:

| # | Constraint | Currently enforced as | Axis | Check mechanism available? |
|---|------------|----------------------|------|---------------------------|
| C1 | ComfyUI daemon must be reachable at `127.0.0.1:8188` | Step 1 bash probe (`curl /login`) | **Do** (pre-flight) | ✅ Already Do-axis |
| C2 | Password must come from Keychain, not hardcoded | Step 2 prose | Think-only | ⚠️ Can add grep-check for plaintext credentials |
| C3 | All prompt submissions must use `client_id: sessionStorage.getItem('clientId')` | Step 7 prose + Subcommands template | **Think-only** | ⚠️ Can add regex pre-commit: any `POST /prompt` without that string → fail |
| C4 | Method B (browser eval) — not curl — for `/prompt` | Step 7 prose + "方案 B 提交模板" section | **Think-only** | ⚠️ Can add check: `/prompt` submissions via `Bash curl` tool calls → warn |
| C5 | Login must happen from browser context (HttpOnly cookie lands in browser jar, not curl jar) | Step 5 prose | **Think-only** | ⚠️ Can add check: no `curl -X POST /login` after setup step |
| C6 | Image upload goes through `/upload/image` endpoint, not direct `cp` to `input/` | "输入图上传" + "已知坑 #1" | **Think-only** | ⚠️ Can add grep-check: `cp .* ComfyUI/input/` → warn |
| C7 | Progress pump Monitor must be persistent, not one-off | Step 8.2 prose | **Think-only** | ⚠️ Can check Monitor invocation args for `persistent: true` |
| C8 | Jwt_token expires (~24h) — must handle re-login | Not explicitly stated | **None** | Gap — needs adding |
| C9 | SUPIR sampler is silent during 10-20min sampling — don't misinterpret as stuck | "已知坑 #2" | **Think-only** | Information-only; no check feasible |
| C10 | Subcommands require setup done first (surface exists, token valid, WS injected) | Not explicitly gated | **None** | ⚠️ Can add pre-flight: `cmux tree | grep surface:<X>` and token-valid probe |

## Enforcement Ratio

- Total constraints: 10
- Think+Do enforced: 1 (C1)
- Do-feasible but only Think: 7 (C2, C3, C4, C5, C6, C7, C10)
- Think-only irreducible: 2 (C8 needs new mechanism; C9 is informational)

**Ratio: 1/10 = 10%** (target: ≥30%)

## Top 3 Think-only Constraints for Upgrade (highest-stakes first)

### Upgrade 1 (highest): C3 — Use browser's sessionStorage.clientId for all submissions

**Why highest**: This is the entire point of "method B." Violating it means UI loses task tracking, Media Assets doesn't populate, user loses co-visibility.

**Do-axis mechanism**:
- Ship a `scripts/lint-submission.sh` that greps any `.sh` / `.md` / transcript for `POST /prompt` without `client_id: sessionStorage.getItem('clientId')` nearby
- In SKILL.md, the submission template becomes a **mandatory include** (skill instructs Claude to `cat references/method-b-submit.sh.tmpl` rather than compose from memory)
- Red line with automated check: "No submission with hardcoded or omitted client_id"

### Upgrade 2: C6 — Image upload via `/upload/image`, not direct `cp`

**Why high**: First-time user who `cp`'s file into `input/` gets confusing 400 response from LoadImage. Wasted cycle.

**Do-axis mechanism**:
- Skill provides `scripts/upload-image.sh` that wraps the correct endpoint call
- Red line: "No `cp` into `~/ComfyUI/input/` — use the upload script"
- Checkable via transcript grep for `cp .* ComfyUI/input`

### Upgrade 3: C10 — Subcommand pre-flight (setup-must-have-run)

**Why high**: Running `/spark-K upscale <image>` without prior `/spark-K` setup skips WS injection → no progress push → user thinks skill is broken.

**Do-axis mechanism**:
- Each subcommand section begins with: "PRE-FLIGHT: verify `window.__sparkK_installed === true` in browser; if false, run setup inline"
- Checkable: any subcommand invocation without prior setup MUST be detectable in skill flow (skill refuses or silently runs setup)

## ADR Audit (P4+P5)

Current state: `docs/adr/` does not exist.

**Missing ADRs** (architecture decisions affecting ≥2 files):

1. **ADR-001: Keychain for credential storage** (affects: SKILL.md setup + cleanup + README) — implicit choice documented only in README prose
2. **ADR-002: Browser-side prompt submission (method B) as default** (affects: SKILL.md + all subcommand templates + README) — central pattern with significant alternatives (direct curl, MCP)
3. **ADR-003: Persistent Monitor with WebSocket event filtering for push notifications** (affects: SKILL.md step 8 + README) — chosen over polling `/api/queue`, significant tradeoff
4. **ADR-004: Template JSON with `{{PLACEHOLDER}}` substitution over builder API** (affects: workflows/ + SKILL.md Subcommands) — domain research shows node-class iteration is more robust

## Summary of Required Phase 2 Actions

- Add explicit `## Red Lines` section with ≥5 checkable constraints, elevating C2–C7 from prose to red lines
- Add Do-axis enforcement scripts for top 3 Think-only constraints
- Create `docs/adr/` with 4 ADRs listed above
- Elevate enforcement ratio from 10% to ≥30% (need 2 more Think+Do conversions beyond C1)
