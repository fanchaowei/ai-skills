# 执行报告

## 交付物

- 完整模块文档：`output/HarborMap.md`
- 执行报告：`output/raw-response.md`
- 索引：未修改。任务要求输出到 `output` 且禁止修改 `fixture`，因此未改写 owner 索引或 fixture 中的旧文档。

## 分析范围

- fixture 根：`fixture/baseline`
- 用户入口：`apps/harbor-system/src/components/harbor-map`
- 读取了目标目录内的组件、类型、adapter、service 和模块内部测试。
- 为确认直接公共依赖，读取了 `packages/shared-ui/src/map-canvas/public.ts` 的公开声明。
- 为识别并排除调用方向，读取了 `apps/harbor-system/src/pages/HarborPage.vue`；其实现、状态和失败回退未写入模块事实。
- 将 fixture 中已有的 `apps/harbor-system/claudedocs/modules/HarborMap.md` 仅作为旧文档线索，并与生产代码重新核对。

## 模块判定

- 仓库模式：monorepo。
- owner：`apps/harbor-system`。
- 模块类型：Vue 组件（`component`）。
- 复杂度：complex。依据是目标边界包含组件、类型、adapter、service 与测试，文件数超过 3，并包含异步请求、数据转换、共享地图契约和并发仲裁。
- 核心功能域：电子围栏显隐编排、围栏数据获取、围栏数据规范化、最新请求仲裁。

## 边界确认结果

| 路径 | 角色 | 依据 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 用户指定目录的主入口，编排其他目标文件并公开 Vue 契约 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 被组件、adapter、service 和测试直接用于模块专属类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 被主入口直接调用，专门完成 Harbor DTO 到共享地图模型的转换 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 被主入口直接调用，提供 Harbor 围栏专用查询边界 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块内部测试，提供稳定验证入口，不作为实现事实来源 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 目标模块真实引用的跨 owner 公开声明，只提取实际使用的最小契约 |
| `apps/harbor-system/src/pages/HarborPage.vue` | caller | 依赖 HarborMap 公开契约，依赖方向指向目标模块，因此无条件排除 |

未发现 owned/shared 冲突、多个独立所有者或只能依赖调用方才能解释的模块行为；无需等待额外边界确认。

## 文档迁移与事实修正

- 旧文档为 `ai-module-spec v2`，任务要求写入完整文档，因此独立迁移为 v3。
- 新文档移除了 v2 的 `key_files`、`tests` 等旧字段，使用 v3 `feature_index` 和固定 `detail_sections`。
- 移除了旧文档中的调用方边界污染与失败回退描述。
- 补全 Vue 四类公开契约，特别是此前遗漏的 `toolbar` slot，并明确 Props、Emits、Slots、Expose。
- 删除了 `passed` 瞬时测试状态，改为长期验证入口的“能证明 / 不能证明 / 扩大条件”范围。
- 依据当前代码补充 `HarborZoneResult`、请求版本仲裁、DTO 规范化、MapCanvas 最小公开依赖及错误/空结果映射。

## 自检结果

- Frontmatter 使用 `doc_type: ai-module-spec` 与 `spec_version: "3.0"`。
- `feature_index` 为 mapping，共 4 个 snake_case 功能域；每项仅包含 `entry` 与 `body_section`。
- `detail_sections` 仅使用固定词汇，必需项齐全，可选项均有对应正文。
- 所有代码路径均为 fixture 仓库根相对正斜杠路径；索引 symbol 均来自当前代码。
- 每个 `body_section` 均可定位到“功能目录”下的真实三级标题。
- Props、Emits、Slots、Expose 已全部扫描并显式记录。
- 直接公共依赖只包含 HarborMap 实际使用的 MapCanvas 公开契约，没有复制 provider 内部实现。
- 正文不包含调用方实现、历史阶段、提交列表、实施进度或瞬时验证状态。
- 验证章节仅描述入口的长期能力边界，测试没有被用来创造生产实现事实。

## 未能自动处理的事项

无。
