# Structural Audit — spark-K

Source: SKILL.md v commit `619f976`, 1610 words body.

## 9-Item Check Table

| # | Check | Result | Evidence | Defect Type |
|---|-------|--------|----------|-------------|
| 1 | SKILL.md exists with valid frontmatter | ✅ PASS | `name: spark-K`, `description: ...`, `Subcommands: ...` present | — |
| 2 | Description has ≥3 concrete trigger phrases (3rd person) | ⚠️ PARTIAL | Has "触发：用户输入 `/spark-K` 或子命令 ..." but written in 2nd person voice ("登录"、"声明") not 3rd ("use when user wants..."). One concrete phrase. | Architecture |
| 3 | Red lines section exists (≥5 mechanically checkable constraints) | ❌ FAIL | No section named "Red Lines"/"红线"/"禁区". Constraints are embedded as prose in "基线假设" and "已知坑". Not checkable by output scan. | Architecture |
| 4 | Acceptance criteria section exists (≥3 testable, user-perspective) | ❌ FAIL | "目标" section lists 4 outcomes but phrased as agent behavior not user-observable pass/fail. | Architecture |
| 5 | Stance defined (cognitive position, not role) | ❌ FAIL | No stance statement. Opens with "# spark-K — ComfyUI 一键协作启动器" (identity) not cognitive position. | Architecture |
| 6 | Referenced files exist | ✅ PASS | `workflows/upscale.json`, `workflows/fast-upscale.json`, `workflows/t2i.json` all present. | — |
| 7 | Imperative voice (no "you should" / "你应该") | ⚠️ PARTIAL | Mix. Many bash-style commands (imperative-ish), but also "告诉用户"、"skill 执行时"、"不做这一步 Claude 就是'盲'的" (reads as narrative/2nd-person). | Mechanical |
| 8 | Backward compatibility (P6): no breaking changes since last tag | ✅ N/A | First published version (commit `6824556`); subsequent commits additive (step 8, subcommands). | — |
| 9 | ADR directory (P4+P5) | ❌ FAIL | `docs/adr/` does not exist. 3 major decisions without records: (a) Keychain for password storage, (b) method B as default, (c) persistent Monitor for push. | Architecture |

## Summary

- **4 Architecture defects** (items 3, 4, 5, 9) — highest priority
- **2 Mechanical defects** (items 2, 7) — batch fixable
- **Passed**: frontmatter valid, files exist, BC intact

## Top 3 Blockers (must fix before Phase 2)

1. No Red Lines section → skill cannot enforce constraints mechanically
2. No Acceptance Criteria → users can't verify success objectively
3. No Stance → instructions read as identity claim ("启动器"), not cognitive position
