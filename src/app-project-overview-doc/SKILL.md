---
name: app-project-overview-doc
description: Use when creating or updating an app-level `claudedocs/PROJECT.md` for an `apps/*` project in a monorepo, especially when the document should help future AI agents quickly understand project positioning, core architecture, reading paths, development entry points, boundaries, and verification guidance without becoming a business page inventory.
---

# App Project Overview Doc

## Goal

Create or update an app-level `claudedocs/PROJECT.md` that works as an AI onboarding overview for one `apps/*` project.

The document should help a future agent quickly answer:

- What is this app responsible for?
- What architecture or runtime pattern matters most?
- Which docs should be read next?
- Which files are the safest entry points for new development?
- Which boundaries should not be crossed?

## Output Positioning

Write `PROJECT.md` as an **AI entry overview**, not as a module document, business page list, or README replacement.

Default target path:

```text
apps/<app-name>/claudedocs/PROJECT.md
```

Default length: **80-120 lines**. Exceed this only when the app has multiple core subsystems that cannot be summarized safely.

## Before Writing

1. Read repository-level agent instructions such as `AGENTS.md`, `CLAUDE.md`, or equivalent files.
2. If the repo requires a clean starting point, handle existing dirty work exactly as the repo instructions say.
3. Read the target app docs, starting with `apps/<app-name>/claudedocs/README.md` when it exists.
4. Read module docs referenced by that README when they describe architecture, runtime ownership, routing, state, API context, or shared-package boundaries.
5. Inspect the app's `package.json`, route entry, layout entry, store entry, and representative shared-package imports.
6. Do not infer the app's purpose from page names alone; identify the organizing architecture behind the pages.

## Recommended Structure

Use this structure unless the app clearly needs a small adjustment:

```markdown
# <app-name> 项目总览

## 项目定位
## 快速阅读路径
## 核心架构心智模型
## <项目核心机制或运行时主线>
## 主要代码入口
## 新开发判断路径
## 边界与注意事项
## 验证建议
```

Choose the core mechanism heading from the app itself. Examples:

- `多上下文工作台`
- `路由与权限模型`
- `地图与设备联动`
- `主站运行时框架`
- `共享视图承载关系`

If the app has two equally important architectural mechanisms, use two short sections instead of forcing them into one.

## Content Rules

### 项目定位

State the app's role in 2-4 short paragraphs. Include the most important architectural distinction.

Good:

- `核心不是普通 Vue Router 单页后台，而是支持多工作区上下文的配置管理工作台。`
- `业务页面是被承载内容，本文件不展开页面内部细节。`

Avoid:

- Listing every page directory.
- Repeating package scripts already covered by root instructions.
- Writing marketing-style descriptions.

### 快速阅读路径

Provide a compact table that points agents to the next documents. Include only paths that help navigation.

Prefer:

- This `PROJECT.md`
- `claudedocs/README.md`
- Key module docs under `claudedocs/modules/`
- Relevant shared package docs when needed

### 核心架构心智模型

Summarize the app's stack, dependency direction, runtime ownership, shared-package relationship, and state/request model.

Keep this section conceptual. The goal is to build the mental model, not to document internal implementation line by line.

### Core Mechanism Sections

Describe the app's main architectural mechanism using:

- Core concepts and identifiers.
- Data or control flow at a high level.
- Important isolation, lifecycle, routing, state, or service-context rules.
- The main reason future development must respect this mechanism.

Use a short `text` flow block only when it makes the control flow easier to scan.

### 主要代码入口

Use a compact table with exact paths and one-line responsibilities.

Include:

- App startup and route/layout entry.
- Main architectural components.
- Primary store or composable entry.
- Shared-package integration points.

Do not include every business page.

### 新开发判断路径

Write task-oriented bullets:

- If changing X, read Y first.
- If adding Y, update Z and test W.
- If touching shared code, check dependency direction.

This section is the handoff from overview to action.

### 边界与注意事项

Capture rules that prevent future agents from making common architectural mistakes.

Common boundaries:

- Do not turn `PROJECT.md` into a page inventory.
- Do not make shared packages depend on apps.
- Do not bypass app-level providers or context boundaries.
- Do not break ids or keys used for instance isolation.
- Do not duplicate module docs here.

### 验证建议

List the smallest useful checks for the app:

- Single-file ESLint command.
- App type-check command.
- App test command or one-test command.
- Shared package checks if shared packages are touched.

If only Markdown changed, say that checking the diff and links is usually enough.

## Quality Checklist

Before finishing, verify:

- The file is at `apps/<app-name>/claudedocs/PROJECT.md`.
- The document is roughly 80-120 lines unless there is a clear reason.
- The first page explains the app's architectural identity.
- Business page internals are not expanded.
- Reading paths are concrete and repo-local.
- Code entry paths are exact.
- Development guidance is task-oriented.
- Boundary notes include shared-package dependency direction when relevant.
- Verification guidance matches the app/package names in this repo.
- Final response reports what was changed and what was verified.
