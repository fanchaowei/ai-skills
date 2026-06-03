# Eval Cases

## Case 1: service/API registry

Prompt:

为 `packages/shared-services/src/service-api-registry.ts` 生成开发使用文档，重点说明功能、输入输出和使用方式。

Expected:

- 生成 `packages/shared-services/docs/modules/service-api-registry.md`。
- 更新 `packages/shared-services/docs/README.md`。
- 包含功能清单、公开输入输出、最小使用示例、主要依赖、设计逻辑、常见修改入口。

## Case 2: Pinia store

Prompt:

为 `apps/config-manage-system/src/store/useManageWorkspaceStore.ts` 生成模块开发使用文档。

Expected:

- 生成 `apps/config-manage-system/docs/modules/useManageWorkspaceStore.md`。
- 更新 `apps/config-manage-system/docs/README.md`。
- 说明 state、getters、actions、使用方式、状态副作用和常见修改入口。

## Case 3: non-monorepo Vue 2.7 composable

Prompt:

为一个非 monorepo Vue 2.7 + Composition API 项目的 `src/composables/useTable.ts` 生成开发使用文档。

Expected:

- 生成 `docs/modules/useTable.md`。
- 更新 `docs/README.md`。
- 不要求识别 Vuex。
