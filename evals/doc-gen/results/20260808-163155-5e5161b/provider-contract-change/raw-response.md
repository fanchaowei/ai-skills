# HarborMap 文档更新执行报告

## 输出

- 完整更新文档：`output/HarborMap.md`
- 完整执行报告：`output/raw-response.md`
- fixture：未修改
- 索引：未修改；fixture 中没有可维护的 owner 索引，且本任务明确指定仅交付上述 output 文件

## 输入与路由

- fixture 根：`fixture/baseline`
- 变化集：`fixture/changes/contract-change.diff`
- 现有文档：`fixture/baseline/apps/harbor-system/claudedocs/modules/HarborMap.md`
- 仓库模式：monorepo（存在 `apps/` 与 `packages/` 路径）
- owner：`apps/harbor-system`
- 模块类型：Vue component
- 文档处理：现有文档为 `ai-module-spec v2`；任务要求写入完整更新文档，因此独立执行 v2 到 v3 的结构迁移

## 边界确认

| 路径 | 角色 | 证据与处理 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 主入口，持有 Vue 契约、显隐编排、并发版本和 provider 结果映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 主入口真实引用的 DTO、Expose 与结果类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 主入口真实引用，专门把 Harbor DTO 转为地图公开模型 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 主入口真实引用的围栏获取入口 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块内部测试，只用于预期与覆盖范围导航 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 主入口和适配器真实引用的跨 owner 公开声明；仅记录最小使用契约 |
| 调用 HarborMap 的页面或其他文件 | caller | 无条件排除；未读取调用方实现以补写模块事实 |

边界证据一致，无需用户确认。旧文档把调用方页面写入 `key_files` 和模块事实，已在 v3 文档中移除。

## provider 公开契约变化分析

`packages/shared-ui/src/map-canvas/public.ts` 的 `MapZoneCommandResult` 新增：

```ts
{ status: 'partial'; count: number; skipped: number }
```

HarborMap 对应变化位于 `HarborMap.vue#setZonesVisible`。组件仍以 `result.status !== 'success'` 进入非成功分支，并显式区分 `empty`；因此：

| provider 结果 | HarborMap 返回 | HarborMap 事件 | 对外字段 |
| --- | --- | --- | --- |
| `success(count)` | `success(count)` | `visible` | 保留 `count` |
| `empty` | `empty` | `error` | 无额外字段 |
| `partial(count, skipped)` | `render-error` | `error` | 不透传 `count`、`skipped` |
| `render-error` | `render-error` | `error` | 无额外字段 |

结论：直接公共依赖契约产生了稳定增量，必须更新“直接公共依赖”、显隐功能事实链、状态/错误映射、跨功能风险与验证范围。HarborMap 自身的 `HarborZoneResult` 联合类型没有新增 `partial`，组件 Expose 公开签名保持不变。

## 文档更新内容

- 将 `doc_type` 文档从 `spec_version: "2.0"` 迁移为 `spec_version: "3.0"`。
- 建立 v3 `feature_index`，索引 `setZonesVisible` 与 `normalizeZone` 的真实 symbol。
- 完整扫描并记录 Vue 四类公开契约：Props、Emits、Slots、Expose；补回旧文档遗漏的 `toolbar` slot。
- 记录 provider 新增 `partial(count, skipped)` 以及 HarborMap 将其吸收为 `render-error` 的边界语义。
- 补充数据转换、状态与错误责任矩阵、并发淘汰语义（包括清除 rejection 不复核版本的边界）、跨 owner 契约验证扩大条件。
- 删除旧文档中的调用方实现、调用方回退描述和 `passed` 瞬时状态。
- 保留当前可由生产代码或模块内部测试支持的事实；未使用旧文档补全未经代码确认的实现。

## 核心功能域

1. `zone_visibility`：`HarborMap.vue#setZonesVisible`，覆盖显示、隐藏、请求、渲染、结果吸收和最新调用优先。
2. `zone_normalization`：`normalize-zone.ts#normalizeZone`，覆盖 DTO 过滤、坐标解析和 `MapZoneModel` 生成。

## 验证与自检

- YAML：使用 `ai-module-spec v3`；`feature_index` 为 mapping；每项仅含 `entry` 与 `body_section`；`detail_sections` 只使用固定词汇并与正文同步。
- 导航：所有索引路径、symbol 和正文功能标题均来自 fixture 中的真实入口。
- 公开契约：Props、Emits、Slots、Expose 四类均已扫描；`partial` 仅记录在直接 provider 契约与模块吸收位置。
- 边界：未纳入 caller；未复制 provider 内部实现；未修改 fixture。
- 事实来源：生产代码用于当前实现和契约，模块测试仅用于预期与长期覆盖范围。
- 验证表述：模块文档不包含 `passed`、`failed`、`not_run`、`blocked` 或任何本次执行状态。
- 按需章节：存在跨 owner 公开依赖、两层以上语义转换和跨功能不变量，因此保留 dependencies、data_flow、risks；未发现需要单列的稳定症状索引或删除边界。
- 测试执行：未执行。任务要求文档分析，且 fixture 未提供项目级依赖或命令配置；文档只记录稳定验证入口及证明边界。

## 阻塞与未自动处理事项

- 阻塞：无。
- 未自动处理事项：无。
