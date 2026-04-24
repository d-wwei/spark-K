# Known Issues

Troubleshooting reference. Load on unexpected failure paths.

## `_remove_sensitive_from_queue` bug in ComfyUI + ComfyUI-Sentinel

**Symptom**: `/api/queue` returns HTTP 500 while a task is running. stderr shows `KeyError: slice(None, 5, None)` inside `server.py:59`.

**Cause**: Stock `_remove_sensitive_from_queue` assumes queue items are tuples and does `item[:5]`. ComfyUI-Sentinel wraps each item as `{"prompt": tuple, "user_id": str}` — a dict, which raises on the slice.

**Resolution**: Patch `~/ComfyUI/server.py` to handle both shapes. Per red line #6, this requires an ADR. Suggested patch (from session 2026-04-24):

```python
def _remove_sensitive_from_queue(queue: list) -> list:
    result = []
    for item in queue:
        if isinstance(item, dict) and "prompt" in item:
            inner = item["prompt"]
            result.append(inner[:5] if isinstance(inner, (list, tuple)) else inner)
        elif isinstance(item, (list, tuple)):
            result.append(item[:5])
        else:
            result.append(item)
    return result
```

Requires ComfyUI daemon restart. Restart kills any running task.

## SUPIR sampler appears stuck at ~50%

**Symptom**: ComfyUI UI shows 50% progress for 10–20 minutes with no updates. CPU of the python process still oscillates 20–60%.

**Cause**: SUPIR's `TiledRestoreEDMSampler` does not emit per-step events to `/ws`. The UI holds the last received progress value until SUPIR is done and VAE decode starts.

**Resolution**: Not stuck — wait. Expected completion in 20 minutes from start on M-series. If CPU drops to 0% for 60+ seconds, then investigate (possible MPS OOM).

## LoadImage: "Invalid image file"

**Symptom**: `/prompt` validation returns `node_errors` for LoadImage.

**Cause**: Image path in workflow doesn't resolve through Sentinel's per-user input routing. Almost always caused by `cp` into `input/` instead of `/upload/image`.

**Resolution**: Use `scripts/upload-image.sh` (see `image-upload.md`).

## jwt_token expired

**Symptom**: Any authenticated endpoint returns 401 after ~24 hours.

**Resolution**: Re-run `/spark-K` setup. Skill will detect expired cookie via `check-setup.sh`, run the login flow, and re-inject the WS subscriber on the updated page.

## Page reload drops the WS subscriber

**Symptom**: Monitor stops receiving events; new task submissions seem invisible.

**Cause**: User (or a skill command) reloaded the browser surface. `window.__sparkK_installed` and `window.__sparkK_events` are gone.

**Resolution**: Re-run `progress-pump.md` step 8.1. Not 8.2 — the Monitor task is still running and will resume drainage once the array reappears.
