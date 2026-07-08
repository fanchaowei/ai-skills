# AI 模块规格文档通用模板

本文档定义 `doc-gen` 的 `ai-module-spec v2` 共享骨架。类型模板可以裁剪可选章节，但不得改变基础 YAML 字段含义。

v2 的核心约束：YAML frontmatter 是索引层，正文是事实层。YAML 只保留 AI 第一眼需要的导航、关键入口、少量风险雷达和验证命令；完整相关文件、完整风险点、完整影响矩阵、完整测试证明点和完整公开契约必须写入正文。

## YAML Frontmatter

```yaml
---
doc_type: ai-module-spec
spec_version: "2.0"
module_name: "{{MODULE_NAME}}"
module_type: "{{MODULE_TYPE}}"
owner: "{{OWNER}}"
audience: ai
read_mode: progressive
depth: "{{DEPTH}}"

summary: "{{MODULE_SUMMARY}}"
primary_use_cases:
  - 快速接手修改代码
  - 理解模块架构
  - 排查问题

entry_files:
{{ENTRY_FILES}}

key_files:
{{KEY_FILES}}

read_order:
  quick_edit:
    - AI 快速接手
    - AI 修改守则
    - 修改指南
    - 已验证行为
  architecture:
    - 模块边界
    - 当前实现契约
    - 核心流程
    - 依赖关系
  debugging:
    - 问题排查路径
    - 影响范围
    - 待确认项

detail_sections:
  files: AI 快速接手
  risks: AI 修改守则
  impact: 影响范围
  tests: 已验证行为
  contract: 当前实现契约

risk_level: "{{RISK_LEVEL}}"
top_risks:
{{TOP_RISKS}}

verification:
  commands:
{{VERIFY_COMMANDS}}
  evidence_section: 已验证行为

status: active
last_updated: "{{ANALYSIS_DATE}}"
last_updated_by: doc-gen
---
```

## YAML v2 字段规则

- `spec_version` 固定为 `"2.0"`。
- `key_files` 只列关键文件，每项包含 `path` 和 `reason`；不要把完整相关文件清单写入 YAML。
- `top_risks` 只列最高优先级风险摘要；不要替代正文完整风险列表。
- `verification.commands` 只列推荐验证命令；不要列完整测试文件。
- `detail_sections` 是字段级索引，用于告诉 AI 完整信息位于哪个正文章节；使用 `files`、`risks`、`impact`、`tests`、`contract` 等新语义 key，不沿用旧 YAML key。
- 完整相关文件清单写入正文 `AI 快速接手`。
- 完整风险点写入正文 `AI 修改守则`。
- 完整影响矩阵写入正文 `影响范围`。
- 完整测试文件和证明点写入正文 `已验证行为`。
- 完整公开契约写入正文 `当前实现契约`。

## 复杂度上限

- 简单模块：YAML 25-40 行，`key_files <= 3`，`top_risks <= 1`，`verification.commands <= 2`。
- 标准模块：YAML 40-70 行，`key_files <= 5`，`top_risks <= 2`，`verification.commands <= 3`。
- 复杂模块：YAML 60-100 行，`key_files <= 8`，`top_risks <= 3`，`verification.commands <= 4`。
- 先按字段上限裁剪，再按行数上限检查。
- 超限时优先裁剪 `key_files` 和 `top_risks`，不得删除 `read_order`、`detail_sections` 或 `verification.commands`。

## 类型契约正文承接

按模块类型在正文 `当前实现契约` 填充完整公开契约。无法从代码确认的字段写为空列表或明确说明未暴露，并在正文 `待确认项` 说明原因。契约不写入 YAML。

- 组件：props、emits、slots、expose。
- Store：state、getters、actions。
- Service：public API、request instances、context provider。
- Composable：parameters、returns、side effects。
- Utility：public functions、input/output、side effects。

## Body

简单模块如果没有可靠排查链路，保留 `问题排查路径` 标题，并用一句话说明未生成具体步骤，原因写入 `待确认项`。

正文必须承接 YAML 索引指向的完整信息，避免为了瘦身而丢失事实。

```markdown
# {{MODULE_NAME}} - {{MODULE_TYPE_DESC}}

## 模块概述

{{MODULE_OVERVIEW}}

## AI 快速接手

{{AI_QUICK_HANDOFF}}

## AI 修改守则

{{AI_CHANGE_RULES}}

## 模块边界

{{MODULE_BOUNDARY}}

## 当前实现契约

{{IMPLEMENTATION_CONTRACT}}

## 核心流程

{{CORE_FLOW}}

## 依赖关系

{{DEPENDENCIES}}

## 影响范围

{{IMPACT_SCOPE}}

## 已验证行为

{{VERIFIED_BEHAVIORS}}

## 修改指南

{{CHANGE_GUIDE}}

## 问题排查路径

{{DEBUGGING_PATHS}}

## 待确认项

{{OPEN_QUESTIONS}}

## 文档维护信息

{{MAINTENANCE_INFO}}
```
