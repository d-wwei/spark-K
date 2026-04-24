---
name: spark-K
description: 一键打开局域网内 ComfyUI 并自动登录 Sentinel。在 cmux 里走内置浏览器分屏；非 cmux 走系统 Chrome。登录完成后声明本会话默认使用"方案 B"——所有 prompt 提交都通过浏览器 JS 上下文（`cmux browser eval` 或 Chrome AppleScript eval）走，使用浏览器的 sessionStorage.clientId，这样提交任务、进度、结果都在 ComfyUI UI 的 Job Queue / Media Assets 里可见可协作。触发：用户输入 `/spark-K`。
---

# spark-K — ComfyUI 一键协作启动器

## 目标

调用后达到以下状态：
1. 浏览器 panel（cmux 内置分屏，或系统 Chrome 新 tab）打开 ComfyUI 主界面
2. Sentinel 已登录（jwt_token cookie 有效）
3. 本会话后续任何 prompt 提交默认走**方案 B**（浏览器 JS 上下文）

## 基线假设

- ComfyUI daemon 监听 `127.0.0.1:8188`（或 `0.0.0.0:8188`）
- Sentinel 作为认证中间件，登录端点 `POST /login`（multipart form: `username`, `password`）
- macOS；Keychain 可用
- cmux 可用时 `CMUX_WORKSPACE_ID` 环境变量存在

## 执行步骤

### 第 1 步：探测 ComfyUI 可达

```bash
/usr/bin/curl -s -m 3 -o /dev/null -w "%{http_code}" http://127.0.0.1:8188/login
```

- 返回 200 → 继续
- 任何其它值 → 停止，告诉用户"ComfyUI 未运行"，并提示启动命令 `cd ~/ComfyUI && bash start.sh`（或你本地实际启动方式）

### 第 2 步：取凭证

```bash
USERNAME="Admin"
PASSWORD=$(security find-generic-password -s "spark-K-comfyui" -a "$USERNAME" -w 2>/dev/null)
```

- `PASSWORD` 非空 → 继续
- 为空 → 通过 AskUserQuestion 让用户输入密码（**注意：问题文本里不要重复密码**），然后：
  ```bash
  security add-generic-password -s "spark-K-comfyui" -a "Admin" -w "$PASSWORD" -U
  ```

### 第 3 步：环境检测

```bash
if [[ -n "$CMUX_WORKSPACE_ID" ]] && command -v cmux >/dev/null 2>&1; then
    MODE=cmux
else
    MODE=chrome
fi
```

### 第 4 步：开浏览器

#### cmux 分支

先查找当前 workspace 是否已经有 ComfyUI 浏览器 surface：

```bash
cmux tree --all 2>&1 | grep -E "browser.*127\.0\.0\.1:8188" | head -3
```

- 已有 → 记录 `SURFACE_ID`（形如 `surface:36`），跳到第 5 步
- 没有 → 创建分屏：

```bash
cmux new-split right --type browser --url "http://127.0.0.1:8188/login"
# 等待 surface 就绪
sleep 2
# 重新读 tree 获取新建的 surface id
SURFACE_ID=$(cmux tree --all 2>&1 | grep -E "browser.*127\.0\.0\.1:8188" | grep -oE "surface:[0-9]+" | tail -1)
```

#### chrome 分支

调用 chrome-control skill 的 preflight（确认"Allow JavaScript from Apple Events"已开），然后：

```bash
osascript -e 'tell application "Google Chrome" to tell front window to make new tab with properties {URL:"http://127.0.0.1:8188/login"}'
osascript -e 'tell application "Google Chrome" to activate'
sleep 2
```

### 第 5 步：登录

**关键点**：登录请求必须从浏览器上下文里发出，这样 jwt_token 自动落到浏览器的 cookie jar（HttpOnly，JS 无法读取）。如果用 curl 登录，cookie 会落到 curl 的 jar 里，浏览器还是没登录。

#### cmux 分支

```bash
cmux browser --surface "$SURFACE_ID" eval "
(async function(){
  const fd = new FormData();
  fd.append('username', 'Admin');
  fd.append('password', $(printf '%s' "$PASSWORD" | /usr/bin/python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'));
  const r = await fetch('/login', {method:'POST', body: fd, credentials:'include'});
  const j = await r.json();
  return JSON.stringify({status: r.status, message: j.message, ok: r.ok});
})()
"
```

成功标志：返回 `{"status":200, "message":"Login successful", "ok": true}`。

登录成功后导航到主界面：

```bash
cmux browser --surface "$SURFACE_ID" navigate "http://127.0.0.1:8188/"
```

#### chrome 分支

密码要做 JS 字符串转义（用 `python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'`），然后：

```bash
osascript -e "tell application \"Google Chrome\" to execute active tab of front window javascript \"$(cat <<JSEND
(async function(){
  const fd = new FormData();
  fd.append('username','Admin');
  fd.append('password', ${PASSWORD_AS_JSON});
  const r = await fetch('/login', {method:'POST', body: fd, credentials:'include'});
  const j = await r.json();
  return JSON.stringify({status: r.status, message: j.message});
})()
JSEND
)\""
```

登录成功后：
```bash
osascript -e 'tell application "Google Chrome" to set URL of active tab of front window to "http://127.0.0.1:8188/"'
```

### 第 6 步：验证

不管哪个分支，验证一下：

```bash
# 通过浏览器 JS 调 /api/queue，必须返回 200
# cmux:
cmux browser --surface "$SURFACE_ID" eval "fetch('/api/queue').then(r=>r.status)"
# chrome:
osascript -e 'tell application "Google Chrome" to execute active tab of front window javascript "fetch(\"/api/queue\").then(r=>r.status)"'
```

- 返回 `200` → 成功，报告给用户
- 返回 `401` → 登录失败，检查密码；若 Keychain 里密码错了，删掉（`security delete-generic-password -s spark-K-comfyui -a Admin`）让下次重新录入

### 第 7 步：声明方案 B 默认

告诉用户：
```
✅ ComfyUI 已就绪，surface = $SURFACE_ID (或 Chrome tab)
✅ 本会话后续 prompt 提交默认走方案 B（通过浏览器 JS）
   → 你在 ComfyUI UI 的 Job Queue / Media Assets 能实时看到进度和结果
```

## 方案 B 提交模板（供本会话后续使用）

所有 `/prompt` 提交**必须**这样发（不再用 curl）：

```bash
# 步骤 A：构造 API 格式的 prompt JSON（每个 node: {class_type, inputs}）并保存到文件
/usr/bin/python3 -c "import json; json.dump({...}, open('/tmp/wf.json','w'))"

# 步骤 B：通过浏览器 eval 提交
PROMPT_JSON=$(cat /tmp/wf.json)
cmux browser --surface "$SURFACE_ID" eval "
(async function(){
  const clientId = sessionStorage.getItem('clientId');
  const body = {client_id: clientId, prompt: $PROMPT_JSON, extra_data: {}};
  const r = await fetch('/prompt', {
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body: JSON.stringify(body),
    credentials:'include'
  });
  return JSON.stringify({status:r.status, response: await r.json()});
})()
"
```

**重点**：
- `client_id: sessionStorage.getItem('clientId')` 是浏览器 WebSocket 连接用的 ID；用它提交，UI 就能把这个任务归属到浏览器本身，在 Job Queue 面板带用户身份显示，Media Assets 里生成缩略图
- 如果直接用 curl 提交，client_id 不是浏览器的，UI 看得到任务但归属是"API 客户端"，不会在 Media Assets 里给你缩略图

## 输入图上传（非核心但常用）

ComfyUI-Sentinel 把 input 文件隔离到 per-user 目录，**不能直接 cp 到 input/ 根目录**，必须走上传 API：

```bash
/usr/bin/curl -s -b <(security find-internet-password ...) -X POST http://127.0.0.1:8188/upload/image \
  -F "image=@/path/to/source.png" \
  -F "overwrite=true"
```

或者从浏览器上下文上传（推荐——cookie 自动带）：

```bash
cmux browser --surface "$SURFACE_ID" eval "
(async function(){
  const fd = new FormData();
  const blob = await fetch('file:///path/to/source.png').then(r=>r.blob());
  fd.append('image', blob, 'source.png');
  fd.append('overwrite','true');
  const r = await fetch('/upload/image', {method:'POST', body: fd, credentials:'include'});
  return JSON.stringify(await r.json());
})()
"
```

注意：`fetch('file://...')` 浏览器里通常会被 CORS 拦——更稳是先把图 base64 读进来再 new Blob。这段细节等真遇到时再处理。

## 已知坑（血泪经验）

1. **`_remove_sensitive_from_queue` bug**：旧 ComfyUI `server.py:59` 期望 tuple，ComfyUI-Sentinel 把 item 包成 dict，导致 `/api/queue` 500。修复：编辑 `~/ComfyUI/server.py` 第 59 行的函数为兼容 dict / tuple 版本（见本会话历史 patch）。**如果用户的 daemon 已经应用过修复就跳过**——skill 第一次跑时可以 `curl /api/queue` 探测，500 就提示用户是否要应用 patch + 重启 daemon。

2. **SUPIR 采样阶段静默**：UI 进度条会停在 50% 不动十几分钟；别误判"卡住"，CPU 还在工作就是正常的。

3. **LAN IP 访问**：skill 默认 `127.0.0.1`，要走局域网（`172.22.20.115:8188` 之类）就启动参数改一下；Sentinel 同样走 cookie，URL 换域不影响登录流程。

## 清理（卸载用）

```bash
security delete-generic-password -s "spark-K-comfyui" -a "Admin"
rm -rf ~/.claude/skills/spark-K
```
