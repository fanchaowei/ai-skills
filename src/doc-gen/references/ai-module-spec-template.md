# AI 模块规格文档通用模板

本文档定义 `doc-gen` 新格式的共享骨架。类型模板可以裁剪可选章节，但不得改变基础 YAML 字段含义。

## YAML Frontmatter

```yaml
---
doc_type: ai-module-spec
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
related_files:
{{RELATED_FILES}}
related_docs:
{{RELATED_DOCS}}

read_order:
  quick_edit:
    - 模块概述
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
    - 已验证行为
    - 待确认项

risk_level: "{{RISK_LEVEL}}"
risk_points:
{{RISK_POINTS}}

downstream_consumers:
  confirmed:
{{DOWNSTREAM_CONFIRMED}}
  inferred:
{{DOWNSTREAM_INFERRED}}

change_impact:
{{CHANGE_IMPACT}}

verified_by:
  tests:
{{VERIFIED_TESTS}}
  commands:
{{VERIFY_COMMANDS}}

{{TYPE_CONTRACT}}

status: active
last_updated: "{{ANALYSIS_DATE}}"
last_updated_by: doc-gen
---
```

## 类型扩展 YAML

按模块类型填充 `{{TYPE_CONTRACT}}`。无法从代码确认的字段写为空列表，并在正文 `待确认项` 说明原因。

```yaml
component_contract:
  props: []
  emits: []
  slots: []
  expose: []

store_contract:
  state: []
  getters: []
  actions: []

service_contract:
  public_api: []
  request_instances: []
  context_provider: []

composable_contract:
  parameters: []
  returns: []
  side_effects: []
```

## Body

简单模块如果没有可靠排查链路，保留 `问题排查路径` 标题，并用一句话说明未生成具体步骤，原因写入 `待确认项`。

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
