# HarborMap 文档更新执行报告

## 交付物

- 完整更新后文档：`output/HarborMap.md`
- 完整执行报告：`output/raw-response.md`
- fixture：未修改
- 索引：未写入。本任务指定交付到 `output`，fixture 中也未提供 owner 或根索引文件作为维护目标。

## 输入与读取范围

- skill：完整读取 `skill/SKILL.md`。
- 必要 references：`repository-routing.md`、`module-detection.md`、`fact-model.md`、`incremental-update.md`、`migration-policy.md`、`complex-module.md`、`ai-module-spec-template.md`、`output-quality.md`。
- 变更集：`fixture/changes/add-feature.diff`。
- 现有文档：`fixture/baseline/apps/harbor-system/claudedocs/modules/HarborMap.md`。
- 模块生产代码与内部测试：`HarborMap.vue`、`types.ts`、`services/harbor-api.ts`、`adapters/normalize-zone.ts`、`HarborMap.spec.ts`。
- 直接公共依赖声明：`fixture/baseline/packages/shared-ui/src/map-canvas/public.ts`。
- 调用方识别：读取 `HarborPage.vue` 仅用于判定角色，未将其实现、状态或回退逻辑写入模块文档。

## 边界确认结果

| 路径 | 角色 | 判定依据 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 主组件入口，拥有公开契约、显隐/高亮编排和状态映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 模块专属 DTO、结果类型和 Expose 接口 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 仅供模块围栏链路使用的专属 service |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 模块专属 DTO→地图模型适配 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块内部稳定验证入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | HarborMap 真实引用的共享公开类型与命令契约 |
| `apps/harbor-system/src/pages/HarborPage.vue` | caller | 通过 HarborMap 公开 Expose 调用目标模块，按硬约束排除 |

边界、owner 和文档落点均可从 fixture 与用户指定输出确定，没有需要用户确认的歧义。

## 变化判定

`add-feature.diff` 产生稳定事实和导航增量：

1. `HarborMapExpose` 新增 `highlightRestrictedZone(id: string): Promise<HarborZoneResult>`。
2. `HarborMap.vue` 新增同名真实 symbol，并加入 `defineExpose`。
3. 当前实现忽略 `_id`，直接委托 `setZonesVisible(true)`；因此高亮入口共享查询、规范化、地图替换、事件、结果类型和并发版本语义，不具备按 id 定位事实。
4. 模块内部测试新增公开 Expose 调用与成功数量预期，但没有证明按 id 选择单个区域。

受影响范围：`feature_index`、功能目录、当前公开契约、跨功能风险、删除边界和验证入口。

## v2→v3 迁移

源文档为 `ai-module-spec v2`，任务要求写出完整更新文档，因此按迁移规则升级到 v3。结构迁移包括：

- 替换旧 `key_files` 和非固定 `detail_sections.tests`。
- 建立 mapping 形式的 `feature_index` 与固定词汇 `detail_sections`。
- 补齐模块概述、边界、四类 Vue 公开契约、功能事实链、直接公共依赖、数据流、诊断、风险、删除边界、验证证明范围和维护信息。
- 清除旧文档中的页面调用方污染、遗漏的 `toolbar` slot 和瞬时测试状态。

## 模块分类与核心功能域

- owner：`apps/harbor-system`
- 模块类型：Vue component
- 文档深度：detailed
- 核心功能域：`zone_visibility`、`restricted_zone_highlight`、`zone_normalization`、`latest_request_wins`

## 自检结果

- YAML 使用 `doc_type: ai-module-spec` 与 `spec_version: "3.0"`。
- `feature_index` 为 mapping，共 4 项，每项只含 `entry` 和 `body_section`。
- `scope`、`contract`、`verification` 必需导航存在；可选导航均有对应正文章节。
- 所有代码路径为 fixture 仓库根相对正斜杠路径；新增 symbol 来自 diff。
- 正文完整扫描 Props、Emits、Slots、Expose，并记录 `toolbar` 与新增高亮 Expose。
- 页面调用方实现、状态、回退逻辑和测试未进入模块文档。
- 未保留历史阶段、提交列表或瞬时验证状态。
- 直接公共依赖仅记录 HarborMap 实际使用的共享地图公开声明。
- 新增高亮功能的入口、委托编排、公开结果、共享依赖和验证入口形成最小事实链。
- 未执行测试命令；验证章节仅描述稳定入口的长期证明范围，不声明某次运行结论。

## 未能自动处理的事项与阻塞

- 未能自动处理的事项：无。
- 阻塞：无。
