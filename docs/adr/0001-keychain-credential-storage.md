# ADR-0001: Use macOS Keychain for Sentinel credential storage

- **Status**: Accepted (2026-04-24)
- **Context**: The skill needs the Sentinel password to auto-login on user invocation. Storing plaintext in a dotfile leaks via backups and shared workstations; prompting on every run defeats the "one-click" goal.
- **Decision**: Store `{service: "spark-K-comfyui", account: "Admin", password: <secret>}` in macOS Keychain via `security(1)`. Skill reads with `security find-generic-password -s ... -a ... -w` at runtime. First run prompts and writes.
- **Consequences**:
  - ✅ No plaintext in repo or transcripts (supports red line #2)
  - ✅ Password survives machine reboots; user can rotate by overwriting (`-U` flag)
  - ❌ Non-macOS users cannot use the skill as-is (Linux `secret-tool`, Windows `cmdkey` would need adapters)
  - ❌ `security` CLI requires Keychain unlock; if locked, first run fails with a clear error
- **Alternatives considered**:
  - Plaintext file (`~/.config/spark-K/credentials`) — rejected for leak risk
  - Prompt every run — rejected for UX friction; violates "one-click"
  - OAuth PKCE against Sentinel — rejected; Sentinel doesn't expose OAuth endpoints
