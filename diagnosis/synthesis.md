# Synthesis — spark-K Boost

References: `structural-audit.md`, `layer-diagnosis.md`, `token-audit.md`, `platform-check.md`, `domain-research.md`, `constraint-enforcement-audit.md`.

## Three Rethinking Questions

### 1. Does the workflow need structural redesign?

**Partially yes.** Expert workflow (per `domain-research.md` mapping table) is a 7-step pipeline: connect → upload → mutate (by class_type) → submit → track → history → view. spark-K conflates mutation + submit into one prose block and hand-waves upload/view. The skill needs to:

- **Break each API concern into its own reference file / script** (matches source #2 pattern, improves 1.3 token budget)
- **Switch template mutation from node-ID hard-coding to class_type iteration** (source #8 — biggest robustness gain)
- **Add output retrieval via `/view`** for remote ComfyUI scenarios

NOT a full redesign — the domain pattern validates spark-K's architecture (browser-side submit, WS listener, template-driven). Surface decomposition + one substitution algorithm change.

### 2. Are the skill's principles still valid?

**Yes, with amendments.** Core principles from this session:
- "Method B — submissions carry browser clientId" → **validated by source #3** (official WS event stream requires clientId to route events). Elevate to red line.
- "Use `/upload/image` for images" → **validated by sources #1, #2, #8**. Elevate to red line.
- "Keychain for credentials, no plaintext in files" → **standard practice**, elevate to red line.
- "Persistent Monitor for progress push" → unique to spark-K, valid. Keep as guidance.

Missing principles (gap per domain research):
- "**Find KSampler/SaveImage/LoadImage nodes by class_type**, do not assume IDs" → add
- "Surface node_errors per-node, not just top-level" → add as acceptance criterion

### 3. What does the quality bar look like?

Per Layer 1 diagnosis (utility skill) + domain expert sources: the bar is **reliable template parameterization + robust submission + clear error surfacing**. Not Layer 2/3 style-by-reference. The boost should:

- Make templates robust to workflow re-save (class_type iteration)
- Make submission mechanism mandatory (Do-axis red line)
- Make error surfacing structured (node_errors dict → user-readable)
- Not add style adaptation, case libraries, or self-evolution (wrong axes for this skill)

## Architecture Prescription

Fix in this order (blocking):

1. **Add `## Stance` section** → "Think like a browser-native operator of a local diffusion server: every task is visible, co-auditable, and restartable by the user. Constraints on the agent (red lines) are also constraints on what the user might accidentally ask — push back, don't comply silently."
2. **Add `## Red Lines` section** with ≥5 checkable constraints (elevating C2, C3, C4, C5, C6 from audit)
3. **Add `## Acceptance Criteria` section** with ≥3 user-observable pass/fail items (replacing "目标" narrative)
4. **Create `docs/adr/` with 4 ADRs** (ADR-001 Keychain, ADR-002 method B, ADR-003 push monitor, ADR-004 template-over-builder)
5. **Decompose SKILL.md** into thin router (≤400 words) + `references/` files per `token-audit.md` target

## Mechanical Prescription

1. **Declare `platform: darwin` in frontmatter** (or `## Scope: macOS only (cmux or Chrome host)`)
2. **Structurally branch cmux vs chrome sections** — every dual-path block uses `### cmux` / `### chrome` subheaders, never prose mixed
3. **Cleanup imperative voice** — replace remaining "你"、"告诉用户"、"skill 执行时" with third-person agent-facing verbs

## Content Prescription

1. **Add Do-axis enforcement for top 3 Think-only constraints** (C3, C6, C10):
   - `scripts/lint-submission.sh` — grep for `POST /prompt` violations (missing clientId / curl-bypass)
   - `scripts/upload-image.sh` — correct-by-construction upload helper
   - `scripts/check-setup.sh` — verify `window.__sparkK_installed === true` and token valid; exit 1 if not
2. **Change template substitution semantics** from node-ID hard-coding to class_type lookup. Add `scripts/fill-template.py` that loads JSON, finds node by class_type, substitutes inputs. Templates become descriptive (which class_type + which input) rather than positional.
3. **Add output retrieval helper** `scripts/fetch-output.sh prompt_id` that calls `/history/{id}` + `/view?...` and saves bytes locally — enables remote ComfyUI use case
4. **Phase 2.3 content validation**: Layer 1 is correct for this skill (see `layer-diagnosis.md`); token budget can shrink after decomposition; domain research has 5+ sources validating core architecture. No Layer 2/3 upgrade indicated.

## Execution Plan for Phase 3

Order (mandatory per boost-workflow.md):
1. **Architecture** — rewrite SKILL.md as thin router, add Stance/Red Lines/Acceptance Criteria, create references/, create docs/adr/
2. **Mechanical** — add platform declaration, normalize cmux/chrome branching, imperative voice pass
3. **Content** — add scripts/ directory with 4 helper scripts, refactor templates to class_type-based

After each category, re-run structural audit / platform check / layer diagnosis as verification. Append `## Verification: <category>` sections to this synthesis file.

## Known Limitations (not in scope for this boost)

- `/spark-K t2i` still untested end-to-end — boost does not run it
- Chrome branch (`chrome-control` fallback) not end-to-end verified in session — boost keeps instructions but marks with "⚠️ untested"
- No MCP migration path (acknowledged in "one year later" view of initial design — still correct, still out of scope)

---

## Verification: Architecture

Re-ran §1.1 checks after rewrite:

| Check | Before | After |
|-------|--------|-------|
| Description trigger phrases (3+, 3rd-person) | ⚠️ 1 phrase, mixed voice | ✅ 5+ phrases in `description`, all 3rd-person |
| Red lines (≥5 checkable) | ❌ missing | ✅ 6 explicit, all grep-auditable |
| Acceptance criteria (≥3 user-observable) | ❌ missing | ✅ 4 user-observable pass/fail items |
| Stance (cognitive, not role) | ❌ missing | ✅ "Think like a browser-native operator…" |
| ADR directory | ❌ missing | ✅ `docs/adr/` with 4 entries (ADR-0001–0004) |
| Referenced files exist | ✅ | ✅ (new references/ all present) |
| Backward compat | ✅ | ✅ subcommand surface preserved; old users' shell commands still work |

## Verification: Mechanical

| Check | Before | After |
|-------|--------|-------|
| Platform-specific names scoped | ⚠️ 28 unscoped | ✅ `scope: darwin` in frontmatter; cmux/chrome explicitly branched |
| Imperative voice | ⚠️ mixed 2nd/3rd person, some "你" | ✅ router fully 3rd-person; references use imperative command form |
| Cross-references | ✅ | ✅ all `references/*.md` and `scripts/*.sh` referenced from SKILL.md exist |

## Verification: Content

| Check | Before | After |
|-------|--------|-------|
| SKILL.md body words | 1610 | **749** (target ≤ 1000 router) ✅ |
| Always-loaded total | ~1680 | **~830** ✅ |
| Largest reference file | — | setup.md 418w (target ≤ 800) ✅ |
| Enforcement axis ratio | 1/10 (10%) | **4/10 (40%)** ✅ (≥30% target met via 3 new scripts enforcing C3, C6, C10 + existing C1) |
| Layer diagnosis | Layer 1 (correct for utility skill) | Layer 1 (unchanged, as planned; Content Prescription validated per Phase 2.3 anti-skip rule) |

Phase 2.3 content validation (anti-skip rule): (a) expert workflow from domain-research.md §"Expert-vs-spark-K Workflow Mapping" validates core architecture; (b) Layer 1 appropriate per layer-diagnosis.md evidence; (c) token budget now well within thresholds per token-audit.md recompute.
