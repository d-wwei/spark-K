# ADR-0004: Frozen API-format JSON templates with `{{PLACEHOLDER}}` substitution

- **Status**: Accepted (2026-04-24), with follow-up planned (see Consequences)
- **Context**: Subcommands (`upscale`, `fast-upscale`, `t2i`) need to submit stock ComfyUI workflows with per-invocation variation (image, prompt, seed, size). Options: (a) store the UI-exported workflow JSON and re-convert to API format at each call, (b) freeze the API-format JSON once with `{{PLACEHOLDER}}` strings for knobs, (c) build a programmatic workflow DSL. Option (c) is expensive; option (a) re-runs the node-schema introspection on every call and breaks if ComfyUI server isn't reachable.
- **Decision**: Go with (b). Convert once (via the session's `convert_workflow.py`), save to `workflows/<name>.json`, substitute at runtime with string `.replace('{{KEY}}', value)`. Each subcommand documents its placeholder list.
- **Consequences**:
  - ✅ Subcommand invocation is offline-friendly: no `/object_info` introspection per call
  - ✅ Changes to ComfyUI custom nodes don't invalidate frozen templates (as long as the schema is still satisfied)
  - ❌ Templates hard-code **node IDs** (e.g. `"5"` for SUPIR_Upscale), fragile if user re-saves the workflow in the UI and node IDs shuffle. Domain research (sources #8, #1) recommends iterating by `class_type` instead.
  - ❌ String `.replace` on JSON is not type-aware; a placeholder meant to be `int` (seed) is replaced with a string, requiring downstream JSON coercion
  - ❌ Placeholder collision with real braces in user prompts is possible (`{{x}}` inside a prompt would be treated as placeholder)
- **Follow-up (tracked)**: Rewrite substitution as `scripts/fill-template.py` that (a) loads JSON, (b) resolves knobs by `class_type + input_name` (e.g. "KSampler.seed"), (c) coerces types. This makes templates robust to node-ID reshuffling. Not blocking for v0.1 but required before v1.0.
- **Alternatives considered**:
  - Live conversion (a) — rejected for offline fragility
  - Workflow DSL (c) — rejected; ComfyUI's JSON IS the de-facto DSL, adding a layer wastes effort
