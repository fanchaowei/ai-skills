代码事实更新判定：无需因 `fixture/changes/bugfix-no-doc-change.diff` 修改模块文档事实。该 diff 只在隐藏操作的异常分支补充 `requestVersion` 检查，使已被后续调用淘汰的操作返回既有的 `superseded` 结果，而不是发布旧操作的错误状态。核对范围包括 `setZonesVisible` 的路径与 symbol、Props、Emits、Slots、Expose、`HarborZoneResult`、MapCanvas 直接公共依赖、诊断状态和验证入口；这些稳定事实与导航均未新增、删除或改名。

必要的格式迁移：现有 `fixture/apps/harbor-system/claudedocs/modules/HarborMap.md` 使用 `ai-module-spec v2`，且任务要求交付完整模块文档，因此独立生成了 v3 文档。该迁移用于修正旧文档结构和边界污染、补齐 v3 导航及当前公开契约，不属于本次 diff 引起的事实更新。

已生成文件：

- `output/HarborMap.md`
- `output/raw-response.md`

模块类型：Vue 组件，复杂度为 complex。核心功能域为电子围栏显隐编排、围栏数据规范化、请求淘汰与状态发布。

边界确认结果：`HarborMap.vue`、`types.ts`、模块内 service、adapter 和测试为 owned；`packages/shared-ui/src/map-canvas/public.ts` 为 direct-public-dependency；`HarborPage.vue` 为 caller，已从模块事实中排除。

自检结果：v3 YAML 固定字段与 detail_sections 合规；feature_index 为 mapping 且入口与正文标题可达；Vue 的 Props、Emits、Slots、Expose 四类契约均已扫描；未写入调用方实现、历史提交或瞬时验证状态；输入文件和索引均未修改。

阻塞：无。
