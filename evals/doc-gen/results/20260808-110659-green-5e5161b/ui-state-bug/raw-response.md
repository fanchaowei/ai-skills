第一检查点是 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` 中 `await mapCanvas.replaceZones(zones)` 前后的事件与结果映射。`ui-state-symptom.diff` 把 `emit('zoneStatusChange', 'visible')` 提前到了渲染调用之前，并让 `render-error` 分支不再发出 `error`；这会产生“渲染失败，但状态事件已经宣告可见”的直接矛盾。该检查点用于定位首个分叉，不单独宣称实际绘制失败的根因。

稳定信号应使用两层结构化结果：`MapCanvasExpose.replaceZones()` 返回的 `MapZoneCommandResult`，以及 `setZonesVisible()` 返回的 `HarborZoneResult`。当两者都指向 `render-error`，却同时观察到 `zoneStatusChange('visible')`，即可稳定确认 HarborMap 的事件时序与渲染结果不一致；此时 `visible` 事件本身不能作为渲染成功证明。

故障边界如下：

- `replaceZones()` 尚未调用：边界仍在查询、DTO 转换过滤或地图引用可用性。
- `replaceZones()` 返回 `render-error`：实际绘制失败位于共享 `MapCanvas` 渲染边界。
- 返回值为 `render-error`，但 HarborMap 已发出 `visible` 或没有发出 `error`：状态污染位于 HarborMap 自己的结果映射与事件时序边界。
- 外部页面如何保存 checkbox 或其他 UI 状态属于调用方，不应写入 HarborMap 模块事实。

下一验证入口是 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`：令 `replaceZones` 返回 `{ status: 'render-error' }`，同时断言公开方法返回 `{ status: 'render-error' }`、事件中没有 `visible` 且存在 `error`。现有测试覆盖隐藏、并发最新请求和 Props/Emits/Slots/Expose，但没有覆盖这个渲染失败分支。

已按需把旧 v2 文档升级为 `ai-module-spec v3`，纠正调用方边界污染，补全 `toolbar` slot、直接公共依赖、数据责任分层、症状诊断、事实冲突和验证证明范围。结果写入 `output/HarborMap.md`。
