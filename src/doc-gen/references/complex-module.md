# {{MODULE_NAME}} - {{MODULE_TYPE_DESC}}

适用于跨文件、跨上下文、状态流或请求链路较复杂的模块。必须优先读取 `ai-module-spec-template.md`，再使用本模板补充复杂模块特有的流程、影响矩阵和排查路径。

复杂模块必须把完整相关文件、完整风险点、完整影响矩阵、完整测试证明点和完整公开契约写入正文。YAML 只保留 `key_files`、`top_risks`、`verification.commands` 和 `detail_sections` 索引。

## 模块概述

{{MODULE_OVERVIEW}}

## AI 快速接手

{{AI_QUICK_HANDOFF}}

## AI 修改守则

{{AI_CHANGE_RULES}}

## 模块边界

{{MODULE_BOUNDARY}}

## 当前实现契约

本章节承接 YAML `detail_sections.contract`。完整公开契约只写在正文，不写入 YAML。

{{IMPLEMENTATION_CONTRACT}}

## 核心流程

{{MERMAID_FLOW}}

{{FLOW_EXPLANATION}}

## 依赖关系

{{DEPENDENCIES}}

## 影响范围

{{CHANGE_IMPACT_MATRIX}}

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
