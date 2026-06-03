---
name: dev-module-doc
description: 生成面向开发人员的功能模块开发使用文档。每当用户要求为 Vue 组件、页面、Pinia store、composable、service/API、工具函数或功能目录生成开发文档、使用文档、模块说明、输入输出说明、接入说明、spec-like 文档时，都应使用本 skill。重点输出模块功能、公开输入输出、最小使用示例、主要依赖、设计逻辑和常见修改入口；文档写入 docs/modules 并维护 docs/README.md。
metadata:
  version: "1.0.0"
  target: "developer-facing module usage documentation"
---

# Dev Module Doc

## 任务

分析用户指定的功能模块，生成面向开发人员的模块开发使用文档。文档帮助开发人员快速了解模块功能、公开输入输出、使用方式、主要依赖、设计逻辑和常见修改入口。

## 输入

- 模块路径：文件或目录，必需。
- 可选上下文：业务说明、设计说明、已有文档或用户补充。
- 可选项目类型：monorepo、非 monorepo、Vue 3、Vue 2.7。

## 执行流程

1. 确认模块路径存在。
2. 按需读取 `references/repository-routing.md`，判断文档落点。
3. 按需读取 `references/module-detection.md`，识别模块类型。
4. 读取目标模块代码和相关类型定义。
5. 按需读取 `references/usage-discovery.md`，使用 `rg` 搜索真实使用方。
6. 按需读取 `references/public-contract.md`，提取公开输入输出。
7. 按 `references/document-template.md` 生成模块文档。
8. 按 `references/index-maintenance.md` 更新 `docs/README.md`。
9. 按 `references/output-quality.md` 自检输出质量。

## 输出

完成后报告：

- 生成或更新的模块文档路径。
- 更新的索引路径。
- 识别到的模块类型。
- 是否找到真实使用方。
- 无法确认的信息。
