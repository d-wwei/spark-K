# Subcommand: `upscale <image>`

Workflow: UltraSharp 4x → ImageScaleToTotalPixels (8.3 MP target) → SUPIR precision restore → SaveImage. Template: `workflows/upscale.json`. Typical duration: 20+ minutes on M-series Apple Silicon via MPS.

## Pre-flight (mandatory, red line #4)

```bash
bash scripts/check-setup.sh "$SURFACE_ID" || exit 1
```

## Args

- `<image>`: local absolute path to source image.

## Placeholders

| Token | Default | Notes |
|-------|---------|-------|
| `{{IMAGE}}` | basename of input | after successful upload, this is the filename Sentinel expects |
| `{{SEED}}` | `42` | SUPIR sampler seed |
| `{{OUT_PREFIX}}` | `upscale_SUPIR` | SaveImage filename prefix |
| `{{A_PROMPT}}` | `"high quality, detailed, sharp"` | SUPIR positive prompt (hallucination guide) |

## Flow

1. Pre-flight: `scripts/check-setup.sh "$SURFACE_ID"`
2. Upload: `bash scripts/upload-image.sh "$IMAGE" "$SURFACE_ID"` (red line #3 — do NOT `cp`)
3. Load template: `cp workflows/upscale.json /tmp/filled-workflow.json`
4. Substitute placeholders in `/tmp/filled-workflow.json` (use python, not sed — JSON escaping)
5. Submit via `method-b-template.md`
6. Progress pump pushes completion. Tell the user the Save path: `~/ComfyUI/output/<user-uuid>/{{OUT_PREFIX}}_00001_.png`

## User-visible output

Completion emits one `🖼  SAVED` push with the filename; `✅ DONE` may also fire depending on ComfyUI version. Expect file size 15–20 MB (4K PNG).
