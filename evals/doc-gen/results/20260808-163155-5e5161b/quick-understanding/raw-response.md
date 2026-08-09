HarborMap 是港区地图组件，主要对外提供电子围栏显隐命令：获取港区围栏数据、将有效数据规范化，并把围栏的绘制或清除委托给共享地图画布。它还通过 `requestVersion` 处理异步命令竞争，确保只有最新命令的结果可以继续提交。

`setZonesVisible` 的真实入口是：

`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

该功能的最小验证入口是：

`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`

最小验证范围至少包括两组组件行为：

1. 隐藏围栏时不调用数据请求，调用 `MapCanvasExpose.clearZones()`，成功后发出 `zoneStatusChange: hidden`，并返回成功且数量为 0。
2. 两个并发显示请求发生时，只把最新请求返回的有效 DTO 经规范化后提交给 `MapCanvasExpose.replaceZones()`，较旧请求返回 `superseded`。

这组最小验证不能证明共享地图的真实渲染、`normalizeZone()` 的边界输入、真实 service 集成、显示与隐藏交错、绘制完成后的淘汰，以及请求、清除、绘制的完整错误矩阵。若修改版本推进点、DTO 规则、异步阶段、公开契约或 MapCanvas 交互，需要扩大组件测试或适配器测试；若跨 owner 修改 `MapZoneModel` 或 `MapCanvasExpose`，还需扩大到 `packages/shared-ui` 的类型与集成验证。
