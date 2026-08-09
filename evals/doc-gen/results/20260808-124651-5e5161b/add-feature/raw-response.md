已根据 `fixture/changes/add-feature.diff` 更新 HarborMap 模块文档，并完成 ai-module-spec v2 到 v3 的结构迁移。

- 文档：`output/HarborMap.md`
- 模块类型：详细 Vue 组件
- 新增契约：`highlightRestrictedZone(id: string): Promise<HarborZoneResult>`
- 核心功能域：电子围栏显隐编排、受限区域高亮入口
- 边界：保留 HarborMap 自有组件、类型、service、adapter 和模块内测试；共享 MapCanvas 仅记录最小直接公共依赖；已排除调用方事实
- 契约核对：Props、Emits、Slots、Expose 四类均已完整记录
- 关键当前语义：`highlightRestrictedZone(id)` 目前委托 `setZonesVisible(true)`，`id` 不参与筛选或渲染命令，因此不承诺单区定向高亮
- 自检：v3 YAML 字段、feature_index 映射、正文锚点、仓库根相对路径、公开契约、依赖与验证证明范围均已核对；未写入历史阶段或瞬时测试状态

未修改 `fixture/` 或 `skill/`，没有阻塞事项。
