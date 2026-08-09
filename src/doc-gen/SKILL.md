---
name: doc-gen
description: 分析 Vue 3 + TypeScript 模块并生成或更新面向 AI 渐进读取的 ai-module-spec 文档。用于需要确认模块边界、记录当前公开契约、定位核心功能入口、提供排障与验证导航，或根据代码变更增量维护模块文档的场景。
---

# 模块文档生成器

## 任务

分析用户指定的 Vue 3 + TypeScript 模块，生成或增量更新 `ai-module-spec v3` 模块文档，并维护对应索引。只记录目标模块拥有的当前事实。

## 输入

- 模块文件或目录路径，必需。
- 可选上下文：用户说明、AGENTS.md、设计或实施文档、现有模块文档、代码 diff。
- 可选路由覆盖：仓库模式、owner 或目标文档路径。

## 执行流程

1. 确认输入路径存在；异常时读取 `references/error-handling.md`。
2. 读取 `references/repository-routing.md`，确定仓库根、owner、文档与索引落点。
3. 读取 `references/module-detection.md` 和 `references/fact-model.md`，识别候选文件角色并执行边界确认门禁。
4. 判断首次生成还是已有文档更新：
   - 首次生成读取 `references/ai-module-spec-template.md`。
   - 已有文档更新读取 `references/incremental-update.md`；涉及 v1/v2 或位置迁移时再读 `references/migration-policy.md`。
5. 已有文档在生成或写入前，按 `incremental-update.md` 判定代码事实与导航增量，并结合用户、任务、执行流程或交付机制是否要求完整文档分流：
   - 仅要求判断且不要求完整文档：无事实或导航增量时报告“无需修改模块文档”；发现增量时报告需要更新及受影响范围。两种情况均不写文件并提前结束。
   - 要求产出、写入或维护完整文档，且源文档为 v1/v2：即使代码无需事实更新，也单独迁移为 v3；报告分别说明“代码无需事实更新”和“仅进行格式迁移”。
   - 源文档为 v3 且无事实或导航增量：不写源文件；必须交付副本时逐字节复制，然后提前结束。
   - 有事实或导航增量时才进入后续局部生成与写入；v1/v2 到 v3 的独立迁移除外。
6. 按模块类型和复杂度读取一个类型模板：
   - 复杂模块：`references/complex-module.md`。
   - Vue 组件：`references/component-simple.md`、`component-standard.md` 或 `component-detailed.md`。
   - Store：`references/store-simple.md` 或 `store-detailed.md`。
   - Service/API：`references/service-standard.md`。
   - Composable：`references/composable-simple.md` 或 `composable-detailed.md`。
   - Utility：`references/utility-simple.md` 或 `utility-detailed.md`。
   - View：`references/view-standard.md`。
7. 构建最多 8 个核心功能域的最小完整事实链，并提取当前公开契约。
8. 生成 v3 YAML 导航与按需正文；不要用篇幅填充缺失事实。
9. 读取 `references/output-quality.md`，执行导航可达性与关键事实一致性自检。
10. 写入文档，并按需读取 `references/index-maintenance.md` 维护 owner 或根索引。

## 硬约束

- 边界不确定时，只输出候选边界表并等待用户确认；确认前不生成最终模块文档。
- `caller` 无条件排除。不得记录调用方实现、状态、测试、回退、修改计划或排障步骤。
- 测试只证明预期和覆盖范围，不得创造实现事实，也不得代表本次已执行通过。
- Vue 公开契约只包括 Props、Emits、Slots、Expose；四类全部扫描，没有公开项时写“无”。
- 文档不记录历史阶段、提交列表、实施进度或 `passed`、`failed`、`not_run`、`blocked` 等瞬时验证状态。
- `feature_index.entry` 使用仓库根相对正斜杠 `路径#symbol`；没有稳定 symbol 时只写路径，不使用行号。
- 直接公共依赖只记录目标模块真实使用的最小公开契约，不复制 provider 内部实现。
- 事实冲突未解决时写入“模块内事实冲突”，不得选一方补写为确定事实。

## 输出契约

- 使用 `doc_type: ai-module-spec` 和 `spec_version: "3.0"`。
- YAML 只保留元数据、一行 `summary`、最多 8 项 `feature_index`、固定词汇 `detail_sections` 和维护元数据。
- `detail_sections.scope`、`contract`、`verification` 必需；`risks`、`dependencies`、`diagnostics`、`data_flow`、`removal` 按正文事实出现。
- 正文基础入口为“模块边界”“当前公开契约”和“验证入口与证明范围”；功能目录承接 `feature_index`，其他主题按触发条件生成。
- “无需修改模块文档”只表示代码没有事实或导航增量；已有文档是否写入、迁移或复制由执行流程第 5 步决定。

## 用户确认点

- 模块边界或 owner 不明确。
- 用户给定范围与代码依赖方向冲突。
- 模块内部事实来源冲突且无法从当前证据解决。
- 历史文档需要移动到新 owner 位置。

## 完成报告

报告生成或更新的文档路径、索引路径、模块类型、核心功能域、边界确认结果、自检结果，以及未能自动处理的事项。已有文档无需事实更新时，明确说明核对范围和理由；仅执行 v1/v2 到 v3 迁移时，与代码变化判定分开报告。
