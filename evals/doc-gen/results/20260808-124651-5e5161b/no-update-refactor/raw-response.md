# 判断结果

无需修改模块文档。

## 核对范围

- 变更集：`changes/internal-refactor.diff`
- 受影响文件：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- 现有文档：`apps/harbor-system/claudedocs/modules/HarborMap.md`
- 导航与契约核对：`HarborMap.vue`、`types.ts`、`adapters/normalize-zone.ts`、`services/harbor-api.ts`、`__tests__/HarborMap.spec.ts`、`packages/shared-ui/src/map-canvas/public.ts`

## 理由

该 diff 仅把既有可见区加载流程拆分为两个组件内部辅助函数：

- `loadZoneDtos()` 封装原有 `fetchHarborZones()` 调用及 `response.code === 200` 判断；
- `buildZoneModels()` 封装原有 `response.data.map(normalizeZone).filter(...)` 转换。

补充的 `HarborZoneDto` 与 `MapZoneModel` 仅用于上述私有辅助函数的类型标注。核对后，下列稳定事实均未变化：

- 文件路径与既有公开 symbol 未改名、未迁移；
- Props `initialZoom`、Emit `zoneStatusChange`、Slot `toolbar`、Expose `setZonesVisible(visible)` 及其返回契约未变化；
- 请求版本淘汰、空数据、请求错误、渲染错误、显示与隐藏的状态语义未变化；
- 对 `fetchHarborZones`、`normalizeZone`、`MapCanvasExpose.replaceZones/clearZones` 的直接依赖契约未变化；
- 诊断信号和 `HarborMap.spec.ts` 验证入口未变化。

因此该变更属于纯内部重构，现有文档导航没有因本次 diff 失效。`output/HarborMap.md` 保留核对后的完整现有文档，不做内容改写。