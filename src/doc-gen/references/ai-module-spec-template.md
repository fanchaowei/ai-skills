# AI 模块规格文档通用模板

本文档定义 `ai-module-spec v3` 共享骨架。YAML 是渐进读取的导航层，正文是目标模块拥有的当前事实层。调用方实现、历史实施记录和瞬时验证状态不属于模块事实。

## YAML Frontmatter

```yaml
---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: "{{MODULE_NAME}}"
module_type: "{{MODULE_TYPE}}"
owner: "{{OWNER}}"
audience: ai
read_mode: progressive
depth: "{{DEPTH}}"
summary: "{{MODULE_SUMMARY}}"

feature_index:
{{FEATURE_INDEX}}

detail_sections:
  scope: 模块边界
  contract: "{{CONTRACT_SECTION}}"
  verification: 验证入口与证明范围
{{OPTIONAL_DETAIL_SECTIONS}}

status: active
last_updated: "{{ANALYSIS_DATE}}"
last_updated_by: doc-gen
---
```

`{{...}}` 是生成模板运行时标记，不是未完成的实施占位符。

## YAML 字段规则

- `summary` 只用一行说明模块当前职责。
- `feature_index` 必须是 YAML mapping：以稳定的 snake_case 功能域名为 key，最多 8 项，只索引稳定核心功能域。每个 key 下只包含 `entry` 和 `body_section`。
- 禁止把 `feature_index` 写成 YAML sequence/list；不得使用 `- entry` 列表项。
- `entry` 使用仓库根相对正斜杠 `路径#symbol`；没有稳定 symbol 时允许只写路径，不使用行号。
- `body_section` 必须指向正文“功能目录”下的真实入口。
- `detail_sections` 只允许 `scope`、`contract`、`verification`、`risks`、`dependencies`、`diagnostics`、`data_flow`、`removal`。
- `scope`、`contract`、`verification` 必需。其他 key 仅在正文同名语义章节真实存在时出现。
- YAML 不保存范围清单、契约详情、症状、风险说明、验证命令或执行状态。

最小合法示例：

```yaml
feature_index:
  zone_visibility:
    entry: apps/example/src/Example.vue#setZonesVisible
    body_section: 电子围栏显隐编排
```

禁止生成 v2 的用途列表、入口文件清单、关键文件清单、阅读顺序、风险等级、风险摘要和验证命令对象。旧字段名只允许在迁移说明或明确禁止项中出现。

## 体积预算

- 简单和标准模块不设置 YAML 最低行数。
- 复杂模块 YAML 目标 50 至 80 行，硬上限 100 行。
- 超限时依次删除重复摘要、下沉详细内容、合并功能域和删除低价值功能索引。
- 不通过行内压缩、缩短真实路径或提高上限处理超限。

## 正文基础骨架

```markdown
# {{MODULE_NAME}} - {{MODULE_TYPE_DESC}}

## 模块概述

{{MODULE_OVERVIEW}}

## 模块边界

{{MODULE_BOUNDARY}}

## 功能目录

{{FEATURE_CATALOG}}

## {{CONTRACT_SECTION}}

{{PUBLIC_CONTRACT}}

{{ON_DEMAND_SECTIONS}}

## 验证入口与证明范围

{{VERIFICATION_SCOPE}}

{{OPEN_QUESTIONS_SECTION}}

{{FACT_CONFLICT_SECTION}}

## 文档维护信息

{{MAINTENANCE_INFO}}
```

基础顺序固定为模块概述、模块边界、功能目录、当前公开契约、验证入口与证明范围、文档维护信息。按需章节插入在公开契约与验证入口之间。

## 验证章节规则

- `能证明` 与 `不能证明` 只描述验证入口的长期能力边界：前者写该入口稳定覆盖的行为，后者写该入口长期不能覆盖的范围；都不得描述某次运行结论。
- 禁止写入任何瞬时验证状态及其自然语言同义表达，例如“本次任务已执行通过”“本次已经验证”“当前检查成功”“运行结果正常”。这些表述即使放在 `不能证明` 中也不允许出现。

## 按需章节

- `直接公共依赖`：存在真实跨 owner 或共享公开契约引用。
- `数据转换与责任分层`：存在至少两层有语义变化的数据转换。
- `问题排查/症状索引`：存在高频、高风险或独立故障边界的模块内症状。
- `状态与错误责任矩阵`：存在多阶段状态、错误映射或并发淘汰结果。
- `删除与保留边界`：功能可独立删除或替换，且有专属实现、接口、状态或测试。
- `跨功能风险`：少量不变量同时影响多个功能域。
- `待确认项` 与 `模块内事实冲突`：仅在确有内容时生成，不加入 `detail_sections` 自由 key。

没有事实时省略按需章节，并同步删除对应可选 `detail_sections` key。正文不设置最低行数，不生成调用方影响矩阵、历史提交列表或验证执行报告。
