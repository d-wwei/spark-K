# Subcommand: `fast-upscale <image>`

Workflow: UltraSharp 4x → SaveImage. Template: `workflows/fast-upscale.json`. Typical duration: 1–2 seconds.

## Pre-flight (mandatory, red line #4)

```bash
bash scripts/check-setup.sh "$SURFACE_ID" || exit 1
```

## Args

- `<image>`: local absolute path to source image.

## Placeholders

| Token | Default |
|-------|---------|
| `{{IMAGE}}` | basename of input |
| `{{OUT_PREFIX}}` | `fast_upscale` |

## Flow

1. Pre-flight: `scripts/check-setup.sh "$SURFACE_ID"`
2. Upload: `bash scripts/upload-image.sh "$IMAGE" "$SURFACE_ID"`
3. Load template + substitute → `/tmp/filled-workflow.json`
4. Submit via `method-b-template.md`
5. Report Save path to user

## When to prefer over `upscale`

- Quick feedback / iterating on crop & source
- Input image is already high-information (≥ 2 MP) — SUPIR would add less value
- Time budget < 1 minute
