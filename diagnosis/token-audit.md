# Token Audit — spark-K

## Counts

| Asset | Words | Threshold | Status |
|-------|-------|-----------|--------|
| SKILL.md body (excl frontmatter) | 1610 | ≤ 2000 | ✅ Healthy |
| Always-loaded total (SKILL.md + frontmatter) | ~1680 | ≤ 3000 | ✅ Healthy |
| workflows/upscale.json | 148 | ≤ 5000 | ✅ Healthy (data file) |
| workflows/t2i.json | 275 | ≤ 5000 | ✅ Healthy (data file) |
| workflows/fast-upscale.json | 55 | ≤ 5000 | ✅ Healthy (data file) |
| README.md | 608 | N/A (not loaded) | ✅ |
| Layer 1 (router in SKILL.md) | 1610 | ≤ 1000 | ⚠️ Over by 610 words |

## Issue: No Layer Decomposition

All content lives in SKILL.md — no `references/` directory. All 1610 words load every time the skill is invoked, even for simple `/spark-K` setup that doesn't need subcommand details.

**Content that should move to references:**

| Content | Current location | Words | Should be |
|---------|-----------------|-------|-----------|
| "方案 B 提交模板" section (lines 163-190) | SKILL.md | ~180 | `references/method-b-template.md` — only loaded when submitting a prompt |
| "输入图上传" section (lines 192-217) | SKILL.md | ~220 | `references/image-upload.md` — only loaded for upscale/fast-upscale |
| "已知坑" section (lines 219-225) | SKILL.md | ~80 | `references/known-issues.md` — loaded on error |
| "第 8 步：启动进度推送" (lines 227-322) | SKILL.md | ~600 | `references/progress-pump.md` — only loaded once per setup |
| "Subcommands" full prose (lines 324-427) | SKILL.md | ~400 | `references/subcommand-<name>.md` — per-subcommand |

After decomposition, SKILL.md router would be ~300 words (frontmatter + stance + red lines + acceptance + dispatch table).

## Implication

SKILL.md currently **monolithic** — violates 4-layer architecture (P6 layer strategy in design-philosophy). Must decompose in Phase 2 content upgrade.

## Target After Boost

| Asset | Target words |
|-------|-------------|
| SKILL.md (router) | ~400 |
| references/setup.md | ~500 (steps 1-8 combined) |
| references/method-b-template.md | ~200 |
| references/subcommand-upscale.md | ~250 |
| references/subcommand-fast-upscale.md | ~150 |
| references/subcommand-t2i.md | ~300 |
| references/image-upload.md | ~250 |
| references/progress-pump.md | ~600 |
| references/known-issues.md | ~150 |
