---
name: dev-module-doc
description: 生成或增量更新面向开发人员的功能模块使用文档。适用于 Vue 组件、页面、Pinia store、composable、service/API、工具函数或功能目录的开发文档、使用说明、输入输出和接入说明。覆盖各项公开功能的用法，将新增功能示例纳入前部使用方式；文档写入 docs/modules，文件名和正文使用简体中文，并维护 docs/README.md。
metadata:
  version: "1.1.0"
  target: "developer-facing module usage documentation"
---

# Dev Module Doc

## 任务

分析用户指定的功能模块，生成面向开发人员的模块开发使用文档。文档帮助开发人员快速了解模块功能、公开输入输出、使用方式、主要依赖、设计逻辑和常见修改入口。

## 使用方式覆盖要求

- `## 使用方式` 是公开功能的用法入口，放在文档前部、公开输入输出和设计逻辑之前；新增用法归入其下的功能或场景子节。
- 每项面向开发者的公开功能都要有对应的接入说明和最小示例。相关功能可以共用一个场景示例，不为每个参数或内部私有方法机械拆分示例。
- 新增或变更公开功能时，同步更新功能清单和使用方式；只在文末追加专题、签名或行为说明不算完成用法覆盖。
- 公开契约不足时明确标记缺口，不编造示例或宣称覆盖完整。具体覆盖检查见 `references/usage-discovery.md`。

## 输入

- 模块路径：文件或目录，必需。
- 可选上下文：业务说明、设计说明、已有文档或用户补充。
- 可选项目类型：monorepo、非 monorepo、Vue 3、Vue 2.7。

## 执行流程

1. 确认模块路径存在。
2. 按需读取 `references/repository-routing.md`，判断文档落点。
3. 按需读取 `references/module-detection.md`，识别模块类型。
4. 读取目标模块代码、相关类型和已有文档；增量更新时结合可用 diff 或用户说明识别公开功能的新增、变更与移除。
5. 按需读取 `references/public-contract.md`，提取公开输入输出。
6. 读取 `references/usage-discovery.md`，建立“公开功能 → 使用小节/示例”的覆盖对应关系，再基于真实契约整理示例。
7. 按 `references/document-template.md` 生成模块文档，确保 `docs/modules/*.md` 的文件名和正文使用简体中文。
8. 按 `references/index-maintenance.md` 更新 `docs/README.md`。
9. 按 `references/output-quality.md` 逐项核对功能覆盖、使用方式位置和增量更新完整性，再检查格式与导航。

## 输出

完成后报告：

- 生成或更新的模块文档路径。
- 更新的索引路径。
- 识别到的模块类型。
- 新增或变更功能的用法覆盖情况。
- 无法确认的信息。
