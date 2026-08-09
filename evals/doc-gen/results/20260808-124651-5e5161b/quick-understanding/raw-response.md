HarborMap 是港口地图的承载组件：它渲染共享地图、透传初始缩放、提供 `toolbar` 插槽，并负责电子围栏的查询、转换、显示、隐藏和并发结果淘汰。

真实功能入口是 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。显示时，它调用 `fetchHarborZones()`，用 `normalizeZone()` 把 DTO 转成 `MapZoneModel`，过滤无效围栏后交给 `replaceZones()`；隐藏时直接调用 `clearZones()`，不请求围栏。每次调用用 `requestVersion` 标记，旧异步结果返回 `superseded`，不会覆盖最新成功状态。当前 `fetchHarborZones()` 只是固定返回 `code: 200` 和空数据，因此未替换 service 的实际路径会返回 `empty`。

模块边界包含 HarborMap 组件、专属 types、adapter、service 和内部组件测试；共享 MapCanvas 只作为直接公共依赖记录最小契约。`apps/harbor-system/src/pages/HarborPage.vue` 是 caller，明确排除，不把页面状态、失败回退或页面测试写成 HarborMap 的事实。

最小验证范围以 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 为锚点，覆盖隐藏时不请求且清除地图、并发显示只保留最新结果，以及公开入口可调用的预期。若只改 DTO 过滤、错误映射或共享地图契约，则分别扩大到 adapter 单元验证、失败分支验证或真实 MapCanvas 集成验证；这些入口描述的是长期证明范围，不表示某次执行结果。
