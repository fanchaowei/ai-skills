HarborMap 是 Harbor 应用里的电子围栏地图组件：对外只需要理解它会按“显示/隐藏”请求来获取、转换、替换或清除围栏，并把结果收敛为 `success`、`empty`、`request-error`、`render-error`、`superseded`。

真实入口是 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。显示链路从这里进入 `fetchHarborZones()`，经 `normalizeZone()` 转为共享地图模型，再调用 `replaceZones()`；隐藏链路直接调用 `clearZones()`。组件用递增版本号保证异步显示请求以最新调用为准。

caller 排除很明确：`apps/harbor-system/src/pages/HarborPage.vue` 只是 HarborMap 的调用方，不属于模块边界；它的页面状态、回退、测试和排障步骤都不应写进 HarborMap 文档。共享 `packages/shared-ui/src/map-canvas/public.ts` 也不是 HarborMap 自有实现，只记录本模块真实使用的 `MapZoneModel`、`clearZones()` 和 `replaceZones()` 最小公开契约。

最小验证范围是 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`：现有用例覆盖隐藏时不请求、只保留最新显示请求结果，以及 Props、Emits、Slots、Expose 的基本可观察契约。它不能证明本次测试已经执行，也没有完整覆盖请求错误、空数据、地图引用缺失、清除失败和替换失败；修改这些分支时应扩大验证。

已生成完整 `ai-module-spec v3` 文档：`output/HarborMap.md`。该文档补全了模块边界、公开契约、电子围栏事实链、直接公共依赖、诊断入口和验证证明范围，并纠正了把 caller 纳入模块事实的边界问题。
