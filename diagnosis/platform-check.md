# Platform Compatibility Check — spark-K

Scan of all SKILL.md references for platform-specific tool names, absolute paths, and platform-dependent features. Per `platform-adaptation.md` mapping table, platform-coupled names should be replaced with semantic verbs.

## Findings

### Platform-specific tool names (SKILL.md)

| Term | Occurrences | Platform | Semantic equivalent |
|------|-------------|----------|---------------------|
| `cmux` | ~18 | cmux (custom) | "integrated browser surface" / "browser-pane host" |
| `cmux browser eval` | 6 | cmux | "inject JS into browser context" |
| `cmux browser navigate` | 2 | cmux | "navigate browser surface" |
| `cmux new-split` | 1 | cmux | "create browser pane" |
| `cmux tree` | 1 | cmux | "enumerate browser surfaces" |
| `osascript` | 2 | macOS | "execute AppleScript command" — but actually, this is fine IF the skill is macOS-only (see "Scope" below) |
| `Google Chrome` | 3 | macOS Chrome | "system browser" |
| `chrome-control skill` | 1 | Claude Code skill | ok to reference (named skill, cross-platform already) |
| `security find-generic-password` / `add-generic-password` | 3 | macOS Keychain | "read from / write to OS credential store" |
| `CMUX_WORKSPACE_ID` | 2 | cmux env | "integrated-pane workspace identifier" |

### Absolute paths

| Path | Cross-platform? |
|------|----------------|
| `~/ComfyUI/server.py` | User-home relative — portable across Unix-like, not Windows |
| `~/.claude/skills/spark-K/workflows/<name>.json` | Portable on Claude Code (uses home dir) |
| `/tmp/comfy_cookies.txt` | Unix-only |
| `/opt/homebrew/bin/python3` / `/usr/bin/python3` | macOS — not documented in SKILL.md but present in helper snippets |

### Platform-dependent features

| Feature | Platforms | Notes |
|---------|-----------|-------|
| macOS Keychain (`security` CLI) | macOS only | No fallback for Linux/Windows |
| AppleScript (`osascript`) | macOS only | No fallback |
| cmux binary | all (cross-platform Electron) | ok |

## Scope Declaration

SKILL.md has an implicit "macOS-only" assumption (LICENSE/README mention it). This is acceptable per `platform-adaptation.md` if **explicitly declared**. Currently:
- README.md line: "macOS (Keychain + AppleScript dependencies)" ✅ declared
- SKILL.md frontmatter: no platform clause ❌ missing

## Issues to Fix (Mechanical)

1. **Missing platform declaration in SKILL.md frontmatter** (add `platform: darwin` or a `## Scope` section stating macOS-only + cmux/Chrome browser host)
2. **`cmux` verbs scattered** throughout prose as if they were universal commands — should be clearly scoped under "cmux branch" blocks (currently they are, but some setup-only prose leaks cmux terms without branching)
3. **`/tmp/` absolute path** for cookies file — not a failure but should be configurable via env var for testability
4. **No fallback for credential store on non-macOS** — either add Linux (`secret-tool`) + Windows (`cmdkey`) fallback paragraphs or explicitly state "macOS-only, contributions welcome for other platforms"

## Summary

**Not clean.** 28 platform-coupled references in SKILL.md. Acceptable because the skill is macOS-scoped, but **scope must be declared explicitly** and cmux vs Chrome branches must be structurally separated (they already are mostly, but setup phase mixes them).

Total platform-specific terms: **28** (vs target: explicit branching under declared scope)
