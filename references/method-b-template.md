# Method B Submission Template

The canonical `/prompt` submission shape. Every subcommand uses this verbatim (red line #1).

```bash
PROMPT_JSON=$(cat /tmp/filled-workflow.json)   # already substituted
cmux browser --surface "$SURFACE_ID" eval "
(async function(){
  const clientId = sessionStorage.getItem('clientId');  // required — red line #1
  const body = {client_id: clientId, prompt: ${PROMPT_JSON}, extra_data: {}};
  const r = await fetch('/prompt', {
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body: JSON.stringify(body),
    credentials:'include'
  });
  return JSON.stringify({status: r.status, response: await r.json()});
})()
"
```

On success: parse the response, extract `prompt_id`, tell the user. Progress Monitor will push completion events.

On `node_errors`: the response contains `{error, node_errors: {<node_id>: {...}}}`. Surface every `node_id` + its errors to the user — do not collapse to a top-level message. Per domain research (source #5), users need node-level specificity to fix workflows.

## Chrome variant

Replace `cmux browser --surface "$SURFACE_ID" eval "<js>"` with:

```bash
osascript -e "tell application \"Google Chrome\" to execute active tab of front window javascript \"<js>\""
```

The same `fetch` body; only the invocation verb differs.
