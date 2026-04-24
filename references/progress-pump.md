# Progress Pump

Inject a WebSocket subscriber and start a persistent Monitor that pushes significant events as notifications. Load during setup and anywhere recovery needs to re-arm after page reload.

## 8.1 Inject WebSocket subscriber

Idempotent — re-running is safe. Execute inside the browser context (`cmux browser eval` or Chrome AppleScript).

```js
(function(){
  if (window.__sparkK_installed) return "already installed";
  window.__sparkK_installed = true;
  window.__sparkK_events = [];
  const clientId = sessionStorage.getItem("clientId");
  const wsUrl = (location.protocol === "https:" ? "wss://" : "ws://") + location.host + "/ws?clientId=" + clientId;
  function connect(){
    const ws = new WebSocket(wsUrl);
    ws.onmessage = (ev) => {
      try {
        const m = JSON.parse(ev.data);
        const t = m.type;
        if (t === "execution_error" || t === "execution_success" || t === "executed" || t === "execution_interrupted" || t === "status") {
          window.__sparkK_events.push({t: Date.now(), type: t, data: m.data});
          if (window.__sparkK_events.length > 500) window.__sparkK_events.splice(0, 100);
        }
      } catch(e){}
    };
    ws.onclose = () => setTimeout(connect, 3000);
  }
  connect();
  return "installed, clientId=" + clientId;
})()
```

## 8.2 Start persistent Monitor

Use the Monitor tool with `persistent: true`. The polling loop drains `window.__sparkK_events` every 2 s and prints only significant events. Each `print(..., flush=True)` line becomes one chat notification.

```bash
while true; do
  cmux browser --surface <SURFACE_ID> eval '
    (function(){
      if (!window.__sparkK_events) return "[]";
      return JSON.stringify(window.__sparkK_events.splice(0));
    })()
  ' 2>/dev/null | /usr/bin/python3 -c "
import sys, json
try:
    s = sys.stdin.read().strip().strip('\"\\'')
    events = json.loads(s) if s else []
    if isinstance(events, str): events = json.loads(events)
except: events = []
for e in events:
    t = e.get('type')
    d = e.get('data') or {}
    pid = (d.get('prompt_id') or '?')[:8]
    if t == 'execution_error':
        nid = d.get('node_id','?')
        msg = (d.get('exception_message') or '')[:200]
        print(f'❌ ERROR node={nid} prompt={pid}: {msg}', flush=True)
    elif t == 'execution_success':
        print(f'✅ DONE prompt={pid}', flush=True)
    elif t == 'executed':
        imgs = (d.get('output') or {}).get('images') or []
        if imgs:
            names = ','.join(i.get('filename','') for i in imgs)
            print(f'🖼  SAVED prompt={pid} node={d.get(\"node\",\"?\")}: {names}', flush=True)
    elif t == 'execution_interrupted':
        print(f'⚠️  INTERRUPTED prompt={pid}', flush=True)
    elif t == 'status':
        q = (d.get('status') or {}).get('exec_info',{}).get('queue_remaining', -1)
        if q == 0:
            print('🏁 QUEUE EMPTY', flush=True)
"
  sleep 2
done
```

Substitute `<SURFACE_ID>` with the cmux surface ref or equivalent Chrome hook.

## Recovery

Page reload drops `window.__sparkK_events` and `window.__sparkK_installed`. The Monitor's `cmux browser eval` returns `"[]"` (array missing means nothing to drain) and the next subcommand's `scripts/check-setup.sh` fails — at that point, re-run 8.1 to re-install. Do not auto-reinject silently; the user's page reload might be intentional and they'd want to know.
