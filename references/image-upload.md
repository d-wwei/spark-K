# Image Upload

Sentinel isolates each user's `input/` directory. A direct `cp` into `~/ComfyUI/input/` or its per-user folder will not be found by the async workflow executor — LoadImage resolves through Sentinel middleware which looks elsewhere. Red line #3 bans the workaround; this reference is the correct path.

## Canonical invocation

```bash
bash scripts/upload-image.sh <local-path> <SURFACE_ID>
```

The helper tries two paths in order:

1. **curl path** — if a Sentinel cookie jar exists (session did curl-login earlier), POST `/upload/image` with multipart form. Fastest, no size ceiling beyond HTTP body limits.
2. **browser path** — base64-encode the file, hand to `cmux browser eval`, let browser build a `Blob` and call `/upload/image` with `credentials: 'include'`. Works without a cookie jar but has the ~2 MB payload ceiling of `cmux browser eval`.

## Response

```json
{"name": "moraine_lake.png", "subfolder": "", "type": "input"}
```

After success, workflows can reference the image by `name` alone — Sentinel handles per-user routing.

## What NOT to do

- `cp /path/to/image.png ~/ComfyUI/input/image.png` — does not appear in LoadImage's search path
- `cp /path/to/image.png ~/ComfyUI/input/public/image.png` — appears in public but requires additional config and is not documented
- Uploading via UI drag-and-drop, then using `/prompt` separately — works, but skill's automation path should go through `/upload/image` directly

## Validation

After upload, `workflows/<name>.json` should reference the image by basename in the LoadImage node's `image` input. The helper's stdout includes the JSON response so the calling subcommand can verify `.type === "input"`.
