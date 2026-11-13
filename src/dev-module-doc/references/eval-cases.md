# Eval Cases

## Case 1: service/API registry

Prompt:

为 `packages/shared-services/src/service-api-registry.ts` 生成开发使用文档，重点说明功能、输入输出和使用方式。

Expected:

- 生成 `packages/shared-services/docs/modules/服务接口注册表.md`。
- 更新 `packages/shared-services/docs/README.md`。
- 模块文档文件名和正文使用简体中文。
- 包含功能清单、公开输入输出、最小使用示例、主要依赖、设计逻辑、常见修改入口。

## Case 2: Pinia store

Prompt:

为 `apps/config-manage-system/src/store/useManageWorkspaceStore.ts` 生成模块开发使用文档。

Expected:

- 生成 `apps/config-manage-system/docs/modules/配置管理工作区状态模块.md`。
- 更新 `apps/config-manage-system/docs/README.md`。
- 模块文档文件名和正文使用简体中文。
- 说明 state、getters、actions、使用方式、状态副作用和常见修改入口。

## Case 3: non-monorepo Vue 2.7 composable

Prompt:

为一个非 monorepo Vue 2.7 + Composition API 项目的 `src/composables/useTable.ts` 生成开发使用文档。

Expected:

- 生成 `docs/modules/表格组合式函数.md`。
- 更新 `docs/README.md`。
- 模块文档文件名和正文使用简体中文。
- 不要求识别 Vuex。

## Case 4: 已有服务文档新增多个公开功能

Prompt:

更新任务服务的开发使用文档。旧文档只有 fetchTasks 的示例，模块现在还公开 executeTask、configureTaskErrorHandling 和 handleTaskError。使用 evals/evals.json 中提供的完整契约与旧文档，不读取仓库中的真实调用方。

Expected:

- 保留 fetchTasks 的有效用法，并让功能清单反映当前公开能力。
- 在前部 `## 使用方式` 中覆盖直接查询、执行器调用、错误策略配置及独立错误处理。
- 可以把配置和错误处理合并为一个场景示例，但不能只在文末另加“执行器”或“错误处理”章节。
- 根据真实导出入口导入，展示必要参数和返回结果处理，不以函数签名列表代替示例。
- 不因默认篇幅建议删掉新增能力的用法，不展开未公开的内部实现。

## Case 5: 组件用法分散与公开能力覆盖

Prompt:

更新记录表格组件的使用文档。基本绑定示例位于使用方式，但多选、工具栏插槽和 clearSelection 的说明散落在后面的专题中。当前公开契约与已有文档见 evals/evals.json。

Expected:

- 在前部 `## 使用方式` 中组织基础绑定、多选与事件处理、工具栏插槽和公开清理方法的最小用法。
- 可以用一个完整组件示例涵盖多项能力，不要求每个 prop、事件或方法独占一个代码块。
- 详细章节可保留设计说明，但不能成为新增能力的唯一接入入口。
- 内部 normalizeRows 不作为业务使用 API 编写示例，也不为它新增用法章节。
- 不能仅因为存在“使用方式”标题和一个旧示例就判定覆盖完整。
