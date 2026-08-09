# HarborMap 文档更新执行报告

## 交付物

- 完整更新文档：`output/HarborMap.md`
- 执行报告：`output/raw-response.md`
- 索引：未写入。任务要求只向 `output` 交付文件，并明确禁止修改 `fixture`；fixture 中也未提供 owner 索引作为输出目标。

## 输入与读取范围

- 完整读取：`skill/SKILL.md`。
- 按任务需要读取：
  - `skill/references/repository-routing.md`
  - `skill/references/module-detection.md`
  - `skill/references/fact-model.md`
  - `skill/references/incremental-update.md`
  - `skill/references/complex-module.md`
  - `skill/references/output-quality.md`
  - `skill/references/ai-module-spec-template.md`
  - `skill/references/migration-policy.md`
- 读取的 fixture 证据：现有 HarborMap 文档、给定 diff、HarborMap 模块生产代码、模块内部测试、caller 文件和共享地图公开声明。
- 未读取仓库、历史结果、设计文档或指定临时目录之外的任何任务资料。
- 未修改 `fixture`。

## 更新判定

- 给定 diff 只修改 `HarborMap.spec.ts`：隐藏用例从“不请求围栏”改为“隐藏前刷新围栏”，并将 `fetchHarborZones()` 期望调用次数从 `0` 改为 `1`。
- 当前生产实现 `HarborMap.vue#setZonesVisible` 的隐藏分支仍直接调用 `clearZones()`，没有调用 `fetchHarborZones()`。
- 因模块内部测试预期与生产实现冲突，不能选择任一方补写为确定事实；完整文档新增“模块内事实冲突”，并在相关功能、契约、依赖和验证范围中避免固化隐藏查询顺序。
- 源文档为 `ai-module-spec v2`，任务要求写入完整更新文档，因此独立执行 v2 到 v3 格式迁移。该迁移不冒充为 diff 引起的生产实现变化。

## 模块识别与边界

- owner：`apps/harbor-system`
- 模块类型：`component`
- 复杂度：`complex`，依据是模块边界包含 Vue 主入口、类型、adapter、service 和内部测试，超过 3 个文件并包含 API 与并发状态语义；使用 detailed 粒度生成。
- owned：
  - `apps/harbor-system/src/components/harbor-map/HarborMap.vue`
  - `apps/harbor-system/src/components/harbor-map/types.ts`
  - `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts`
  - `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts`
  - `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`
- direct-public-dependency：`packages/shared-ui/src/map-canvas/public.ts`
- caller 并已排除：`apps/harbor-system/src/pages/HarborPage.vue`
- 边界确认结果：依赖方向和专属性证据足够，无 owned/shared 歧义；无需边界确认暂停。

## 核心功能域

1. `zone_visibility`：电子围栏显隐编排。
2. `zone_normalization`：围栏 DTO 到地图模型的规范化。
3. `request_supersession`：并发请求版本控制与过期结果淘汰。

## 公开契约核对

- Props：`initialZoom?: number`，默认值 `12`。
- Emits：`zoneStatusChange(status: 'visible' | 'hidden' | 'error')`。
- Slots：`toolbar`，无 slot props。
- Expose：`setZonesVisible(visible: boolean): Promise<HarborZoneResult>`。
- 四类 Vue 公开契约均已扫描；旧文档遗漏的 `toolbar` slot 已补入。

## v3 迁移内容

- 使用 `doc_type: ai-module-spec` 和 `spec_version: "3.0"`。
- 删除 v2 的 `key_files`、`tests` detail key、基线说明和瞬时 `passed` 状态。
- 建立 mapping 形式的 `feature_index`，只含 `entry` 与 `body_section`。
- 建立固定词汇 `detail_sections`，保留必需的 scope、contract、verification，并按事实增加 dependencies、data_flow。
- 删除 caller 的实现、状态和失败回退描述；caller 只在边界表中标记为排除。
- 增加当前完整 Props、Emits、Slots、Expose 契约、直接公共依赖、数据责任和稳定验证范围。

## 自检结果

- YAML：字段为 v3；`feature_index` 是 snake_case mapping，共 3 项；每项只含 `entry` 与 `body_section`；必需 detail key 齐全，可选 key 与正文同步。
- 导航：所有 feature entry 使用仓库根相对正斜杠路径和真实 symbol；所有 body section 在“功能目录”中可达。
- 边界：caller 未进入模块事实；共享 provider 只记录模块实际使用的最小公开契约。
- 事实：生产代码、更新后测试预期和旧文档已按证据用途区分；冲突未被改写为确定事实。
- Vue 契约：Props、Emits、Slots、Expose 四类已完整扫描。
- 验证：只记录验证入口的长期证明范围，不记录 `passed`、`failed`、`not_run`、`blocked` 或其自然语言同义状态。
- 内容：未写入历史阶段、提交列表、实施进度、调用方回退逻辑、provider 内部实现或失效引用。
- fixture：未修改。

## 未能自动处理的事项

- 模块内事实冲突尚未解决：需要维护者确认 `setZonesVisible(false)` 是否应在 `clearZones()` 前调用 `fetchHarborZones()`，或确认更新后的测试预期是否应调整。该冲突不阻止生成合规文档，但阻止将隐藏查询顺序声明为稳定契约。
