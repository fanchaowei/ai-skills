已为 `apps/harbor-system/src/components/harbor-map` 生成完整的 `ai-module-spec v3` 文档：`output/HarborMap.md`。

文档确认的模块边界包括 `HarborMap.vue`、模块专属 `types.ts`、`services/harbor-api.ts`、`adapters/normalize-zone.ts` 和模块内测试；`packages/shared-ui/src/map-canvas/public.ts` 仅作为直接公共依赖记录最小契约，调用方和共享画布内部实现不纳入模块事实。

当前公开契约已完整扫描：

- Prop：可选 `initialZoom: number`，默认值为 `12`。
- Emit：`zoneStatusChange`，载荷为 `visible | hidden | error`。
- Slot：具名 `toolbar`，无 slot props；默认 slot 无。
- Expose：`setZonesVisible(visible: boolean): Promise<HarborZoneResult>`；其他 expose 无。

电子围栏的关键入口是 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。文档追踪了隐藏清空、显示取数、DTO 规范化、画布替换、结果/事件映射和 `requestVersion` 并发淘汰链路，并明确记录当前 `fetchHarborZones` 固定返回空数据的实现事实。

验证范围以 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 为稳定入口，覆盖隐藏不取数、两个显示请求的较新结果优先，以及 Props/Slots/Expose/隐藏事件的预期；文档同时列出它不能证明的 adapter 非法输入、错误/空分支、已启动画布操作的竞态、真实 API 和真实地图渲染范围。测试期望没有被写成实现事实，也没有记录瞬时执行状态。

未遇到需要用户确认的边界冲突或其他阻塞。
