已生成增量更新结果：

- 模块文档：`output/HarborMap.md`
- 响应记录：`output/raw-response.md`
- 模块类型：`component`，当前复杂度为 `simple`
- 边界：当前只保留 `HarborMap.vue` 为 owned；`@shared/ui/map-canvas` 是直接公共依赖；页面调用方未纳入模块事实

处理方式：

1. 基线文档是 `ai-module-spec v2`。本次属于已有文档更新，因此先按迁移规则升级为 v3；这是首次 v3 升级允许的结构性改写，之后只保留最终状态涉及的索引和章节。
2. 全部 diff 都以同一基线为原点，没有可依赖的提交时间顺序。对同一路径和 symbol 的冲突采用“完整删除优先于对已删除实现的局部新增、修改、重构或修复”的合并规则；除非存在明确的删除后新增证据，否则不复活被删除能力。
3. `remove-feature.diff` 完整删除围栏请求、转换、异步显隐编排、Expose 方法、专属类型、服务、适配器和模块测试。因此 `add-feature.diff`、`modify-feature.diff`、`dto-change.diff`、`internal-refactor.diff`、`bugfix-no-doc-change.diff`、`ui-state-symptom.diff` 对这些已删除事实的变化均不进入最终文档。
4. `contract-change.diff` 扩展了共享 `MapZoneCommandResult`，但最终 HarborMap 不再引用 `MapCanvasExpose`、`MapZoneModel` 或调用区域命令，所以该共享契约变化不再影响 HarborMap 的直接使用契约。
5. `fact-conflict.diff` 中测试对隐藏前请求的期望与基线实现冲突，但该测试和对应显隐能力在最终状态中均被删除，冲突没有存续为当前模块事实，因此未生成“模块内事实冲突”章节。
6. 最终文档只索引仍存在的“地图画布渲染”和“工具栏插槽”，公开契约保留 `initialZoom`、`zoneStatusChange` 声明和 `toolbar` slot，Expose 明确为“无”；验证章节移除已删除测试及瞬时状态。

阻塞：无。
