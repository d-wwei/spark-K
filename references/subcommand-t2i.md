# Subcommand: `t2i "<prompt>"`

Workflow: Flux2 text-to-image → UltraSharp 4x → ScaleToTotalPixels → SUPIR → SaveImage. Template: `workflows/t2i.json`. Typical duration: 25–35 minutes on M-series Apple Silicon.

⚠️ **Untested end-to-end** as of skill boost (2026-04-24). SUPIR and Flux2 node schemas validated against `/object_info`, but actual run not completed. First invocation may surface node validation errors — surface them to the user verbatim.

## Pre-flight (mandatory, red line #4)

```bash
bash scripts/check-setup.sh "$SURFACE_ID" || exit 1
```

## Args

- `<prompt>`: positive prompt string. Keep to ≤ 200 tokens for best Flux2 behavior.
- Optional inline args after the prompt:
  - `size=WIDTHxHEIGHT` → substitutes `{{WIDTH}}`/`{{HEIGHT}}`
  - `seed=N` → substitutes `{{SEED}}`
  - `neg="<neg_prompt>"` → substitutes `{{NEG_PROMPT}}`

## Placeholders

| Token | Default |
|-------|---------|
| `{{PROMPT}}` | required |
| `{{NEG_PROMPT}}` | `"blurry, low quality, distorted, watermark, ugly, deformed"` |
| `{{WIDTH}}` × `{{HEIGHT}}` | `1360 × 768` |
| `{{SEED}}` | `42` |
| `{{SUPIR_SEED}}` | `42` |
| `{{A_PROMPT}}` | `"high quality, detailed, sharp, photorealistic"` |
| `{{OUT_PREFIX}}` | `t2i_SUPIR` |

## Flow

1. Pre-flight
2. Load `workflows/t2i.json` + substitute → `/tmp/filled-workflow.json`
3. Submit via `method-b-template.md`
4. If response has `node_errors`: stop and surface them (Flux2 models or SUPIR config may have drifted)
5. Progress pump pushes completion; expect `🖼  SAVED prompt=... t2i_SUPIR_00001_.png`

## Validation before first use

If this is the first run on a fresh ComfyUI install, verify these are present via `/object_info`:

```bash
/usr/bin/curl -s "http://172.22.20.115:8188/object_info/UNETLoader" | grep -q "flux2-dev.safetensors" || echo "missing UNET"
/usr/bin/curl -s "http://172.22.20.115:8188/object_info/CLIPLoader" | grep -q "mistral_3_small_flux2_bf16" || echo "missing CLIP"
/usr/bin/curl -s "http://172.22.20.115:8188/object_info/VAELoader" | grep -q "flux2-vae" || echo "missing VAE"
```

If any print, the template will fail at `/prompt` validation. Report the missing model to the user.
