已根据 `add-feature.diff` 更新 HarborMap 模块文档，并把原有 `ai-module-spec v2` 升级为 v3。

本次更新包括：

- 修正模块边界：保留 HarborMap 组件、类型、专属 service、adapter 和模块测试；共享地图声明仅作为直接公共依赖，不再把页面层实现写入模块事实。
- 完整扫描并记录 Vue 公开契约：`initialZoom` Prop、`zoneStatusChange` Emit、`toolbar` Slot，以及 `setZonesVisible()`、新增 `highlightRestrictedZone()` 两个 Expose 方法。
- 明确新增方法的当前语义：`highlightRestrictedZone(id)` 目前直接复用 `setZonesVisible(true)`，`id` 尚不参与单个围栏筛选；测试只能证明公开方法可调用并返回成功计数，不能证明定点高亮。
- 补充围栏获取、标准化、共享地图渲染、最新请求生效、状态与错误映射、直接依赖、风险、删除边界及稳定验证入口。
- 移除旧文档中的调用方状态、遗漏契约和 `passed` 等瞬时验证状态。

产物：

- `output/HarborMap.md`：更新后的完整 `ai-module-spec v3` 文档。
- `output/raw-response.md`：本次面向用户的完整回复。

索引未修改：fixture 未提供 `apps/harbor-system/claudedocs/README.md`，且本次隔离任务只要求在 `output/` 生成上述两个产物。

边界确认完成，未发现需要用户确认的事实冲突或其他阻塞。
