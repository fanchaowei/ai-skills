第一检查点是 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` 的显示分支，重点看这三个动作的顺序：先 `emit('zoneStatusChange', 'visible')`，再等待 `mapCanvas.replaceZones(zones)`，最后处理非成功结果。变化集把 `visible` 提前到了实际渲染之前，同时让结构化 `render-error` 分支不再发送 `error`，因此两个公开信号会发生分叉。

- 稳定信号：在查询得到有效围栏、`replaceZones()` 解析为 `{ status: 'render-error' }` 时，Expose 方法稳定返回 `{ status: 'render-error' }`，但 `zoneStatusChange` 事件流中已有 `visible`，并且没有后续 `error`。这比观察外部 UI 更稳定，因为它完全位于 HarborMap 的公开边界内。
- 故障边界：共享 MapCanvas 已通过结构化结果报告渲染失败；HarborMap 正确返回了 `render-error`，但它拥有的事件编排仍保留 `visible`。所以“渲染为何失败”在 MapCanvas 边界内，“失败后 UI 状态为何仍是开启”则落在 HarborMap 的事件顺序与结果映射边界。查询失败、规范化为空和 `replaceZones()` 抛异常会产生不同信号，不应混为同一故障。
- 下一验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。该文件已有 `fetchHarborZones` 和 `replaceZones` mock，可让查询返回一个有效 DTO、让 `replaceZones` 返回 `render-error`，然后同时观察 `setZonesVisible(true)` 的返回值和 `zoneStatusChange` 顺序。当前症状的判别式是“返回 `render-error`，事件只有 `visible`”；用于回归约束时，应确保 `visible` 只代表已成功替换围栏，渲染失败不能留下最终可见状态。

已生成完整的 v3 模块文档 `output/HarborMap.md`。文档已从旧 v2 结构升级，补齐 Props、Emits、Slots、Expose，排除页面调用方，记录共享 MapCanvas 的最小公开依赖，并加入数据流、状态矩阵、症状导航、稳定信号、故障边界和验证证明范围。未修改 `fixture/` 或 `skill/`，也未把测试文件中的预期写成本次已执行结果。
