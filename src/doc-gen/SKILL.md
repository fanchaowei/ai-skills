---
name: doc-gen
description: 智能模块文档生成器 - 分析 Vue 3 + TypeScript 代码模块，生成 AI 优化的结构化模块文档；兼容 monorepo 与非 monorepo 项目，自动识别模块边界、文档归属、索引落点，并按需维护 claudedocs 与 AGENTS.md 索引。
metadata:
  author: 范超威
  version: "1.1.0"
  created: "2026-03-06"
  updated: "2026-06-02"
---

# 智能模块文档生成器

## 任务

分析用户指定的 Vue 3 + TypeScript 模块，生成 AI 友好的结构化模块文档，并维护对应索引。兼容 monorepo 与非 monorepo 项目。

## 输入

- 模块路径：文件或目录，必需。
- 可选上下文：设计文档、实施说明或用户描述。
- 可选模式覆盖：用户可说明这是 monorepo、非 monorepo，或指定 owner。

## 执行流程

1. 确认模块路径存在；路径不存在时按 `references/error-handling.md` 处理。
2. 按需读取 `references/repository-routing.md`，判断仓库模式和 owner。
3. 按需读取 `references/module-detection.md`，识别模块边界、类型和复杂度。
4. 根据模块类型和复杂度选择现有模板文件。
5. 分析代码，提取职责、入口、依赖、状态、API、事件、TODO 和修改提示。
6. 生成模块文档到目标 `claudedocs/modules/`。
7. 按需读取 `references/index-maintenance.md`，更新根索引或 owner 索引。
8. 如果发现根级旧文档，按 `references/migration-policy.md` 先列迁移计划并等待用户确认。
9. 按 `references/output-quality.md` 检查输出质量。

## 文档路由

- 用户说明优先于自动识别。
- monorepo：`apps/*`、`packages/*`、`libs/*` 写入对应 owner 的 `claudedocs/modules/`。
- 非 monorepo：写入根 `claudedocs/modules/`。
- monorepo 根 `AGENTS.md` 只维护 owner 文档入口。
- owner `claudedocs/README.md` 维护模块中等摘要。

## 模块识别

按需读取 `references/module-detection.md`，识别模块边界、模块类型和复杂度。识别结果不明确时，列出候选文件并要求用户确认。

## 索引维护

按需读取 `references/index-maintenance.md`。monorepo 根 `AGENTS.md` 只维护 owner 入口，owner README 维护模块摘要；非 monorepo 沿用根模块索引。

## 历史迁移

按需读取 `references/migration-policy.md`。发现根级旧文档时，先列出迁移计划并等待用户确认；不能直接移动。

## 质量与错误处理

按需读取 `references/output-quality.md` 和 `references/error-handling.md`。无法判断路径、类型或 owner 时先询问用户。

## 用户确认点

- 模块边界不明确。
- monorepo owner 不明确。
- 历史根级文档需要迁移。
- 用户上下文与代码分析冲突。

## 输出

完成后报告：

- 生成或更新的模块文档路径。
- 更新的索引路径。
- 模块类型和复杂度。
- 迁移计划或迁移结果。
- 未能自动处理的事项。
