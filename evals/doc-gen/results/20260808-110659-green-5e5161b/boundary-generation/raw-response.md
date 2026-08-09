已生成并升级 HarborMap 模块文档：

- 文档路径：`G:\Users\FANCHA~1\AppData\Local\Temp\doc-gen-eval-20260808-110659-green-5e5161b-boundary-generation\output\HarborMap.md`
- 模块类型：Vue 组件，按 detailed 深度记录。
- 核心功能域：地图容器与工具栏、电子围栏显隐编排、电子围栏查询入口、围栏数据归一化。
- 边界确认：`harbor-map` 内组件、类型、专属 service、adapter 和内部测试属于模块；`packages/shared-ui/src/map-canvas/public.ts` 仅作为直接公共依赖；`HarborPage.vue` 是 caller，已从模块事实中排除。
- 电子围栏主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`；查询入口为 `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones`，转换入口为 `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。
- 公开契约：已完整扫描 Props、Emits、Slots、Expose，并补齐 `toolbar` slot、`setZonesVisible()` 的结果状态及事件触发边界。
- 验证范围：已记录 `HarborMap.spec.ts` 能证明和不能证明的稳定范围，以及 adapter、service 或共享地图契约变化时需要扩大的检查范围；未写入瞬时测试状态。
- 索引：未修改。任务指定写入独立 output 路径，没有改写 fixture 仓库索引。
- 自检：v3 YAML 字段、功能入口、正文锚点、路径与 symbol 均可达；可选章节与 `detail_sections` 一致；未包含调用方实现、历史阶段或瞬时验证状态。
- 未能自动处理的事项：无。
