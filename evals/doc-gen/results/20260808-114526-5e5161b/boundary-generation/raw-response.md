已生成 HarborMap 的 `ai-module-spec v3` 模块文档：`output/HarborMap.md`。

文档把 `apps/harbor-system/src/components/harbor-map` 内的组件、类型、adapter、service 和模块内部测试确认为 owned 边界；把共享 `MapCanvas` 公开声明作为直接公共依赖；明确排除了所有调用方实现。公开契约完整记录了 `initialZoom` Prop、`zoneStatusChange` Emit、`toolbar` Slot，以及 `setZonesVisible()` Expose 与全部结果联合类型。

电子围栏入口定位到 `HarborMap.vue#setZonesVisible`，并串联 `fetchHarborZones()`、`normalizeZone()`、`MapCanvasExpose.replaceZones()/clearZones()`、请求版本淘汰、公开结果和事件。验证章节说明了 `HarborMap.spec.ts` 当前表达的预期、不能证明的范围，以及 adapter、service、公开契约和共享画布变化时应扩大的检查范围；没有把测试文件写成本次执行结果，也没有推测 fixture 中不存在的项目命令。

已完成 v2 到 v3 的结构迁移和导航自检：`feature_index` 为 mapping，路径与 symbol 均来自 fixture，正文入口与 `detail_sections` 对应，未保留调用方事实、旧版瞬时状态或历史说明。评测要求仅写入 `output/`，因此未修改 fixture 内原文档或索引。
