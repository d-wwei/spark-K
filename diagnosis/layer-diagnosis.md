# Knowledge Layer Diagnosis — spark-K

## Tests Applied

### Layer 1 test: structural rigidity
- Task A: `/spark-K upscale <image>` → Template substitution of `{{IMAGE}}/{{SEED}}/{{OUT_PREFIX}}/{{A_PROMPT}}` → fetch /prompt
- Task B: `/spark-K t2i "<prompt>"` → Template substitution of `{{PROMPT}}/{{WIDTH}}/{{HEIGHT}}/{{SEED}}/...` → fetch /prompt
- **Result**: Identical 3-phase structure (read template → replace → POST). Different topic (image vs text), same rhythm.

### Layer 2 test: style-by-reference
- Prompt "make it like X's upscale approach" → skill has no mechanism to interpret X. Pure template replacement.
- **Result**: Does not capture category/style nuance. No parameter mapping from reference to workflow knobs.

### Layer 3 test: auto-correction
- Inject deliberate error (e.g., `{{SEED}}=abc`) → skill would POST it as-is, ComfyUI rejects with 400. Skill does not proactively detect+correct.
- **Result**: No self-correction.

## Layer Determination: **Layer 1** (structured automation)

## Is Layer 1 Appropriate?

**Yes, for the current scope.** This skill's purpose is deterministic: open browser, log in, post stock workflows. It is a **utility** skill (tool/transformation domain) not an analysis/creative skill. Per `se-kit-integration.md` guidance, Layer 1 + zero self-evolution is correct positioning.

**Upgrade to Layer 2 would be warranted if**: user starts describing desired *style* of image ("match my Instagram grid"), in which case skill would need style-parameter mapping. Not in scope today.

## Evidence

- 3 frozen JSON templates under `workflows/` — by design, identical shape
- No "adapt to reference" logic anywhere in SKILL.md
- Subcommand dispatch is a 4-entry switch (including empty → setup-only)

## Implication for Phase 2

- **Do NOT** push Content upgrades aimed at Layer 2/3 — wrong direction for a utility skill
- **DO** push Architecture upgrades (red lines, acceptance criteria, stance, ADR)
- **DO** tighten the Layer 1 mechanisms: make templates schema-validated, enforce "setup-before-subcommand", codify the "must use clientId from sessionStorage" rule as a Do-axis check
