---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: complex-module
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 负责电子围栏的请求、有效边界规范化、最新请求淘汰与地图画布显隐编排。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 电子围栏数据规范化
  zone_fetching:
    entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones
    body_section: 电子围栏数据获取

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  diagnostics: 问题排查与症状索引
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 电子围栏地图模块

## 模块概述

HarborMap 将电子围栏接口数据转换为地图画布可消费的区域模型，并通过公开的异步显隐命令协调请求、并发淘汰、清除、替换、结果返回和状态事件。

## 模块边界

| 路径 | 角色 | 模块内职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 公开契约、显隐编排、请求版本状态、结果与事件映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 围栏 DTO、公开命令结果和 Expose 类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 围栏 DTO 到地图区域模型的规范化与过滤 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 围栏请求公开入口与响应类型 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 组件公开契约、隐藏流程和最新请求语义的预期覆盖入口 |
| `apps/harbor-system/src/components/harbor-map/adapters/__tests__/normalize-zone.spec.ts` | owned | 四个有效边界点规则的预期覆盖入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | HarborMap 实际使用的地图区域模型与画布命令契约 |

`apps/harbor-system/src/pages/HarborPage.vue` 是 HarborMap 的调用方，不属于本模块；其状态、失败回退、测试和实现均不构成 HarborMap 模块事实。

## 功能目录

### 电子围栏显隐编排

- 真实入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。
- 每次调用递增 `requestVersion`；异步阶段完成后若版本已落后，返回 `{ status: 'superseded' }`，不继续提交旧结果。
- 隐藏分支不请求围栏，调用 `MapCanvasExpose.clearZones()`；清除成功时发出 `zoneStatusChange: 'hidden'` 并返回 `{ status: 'success', count: 0 }`，清除异常时发出 `'error'` 并返回 `render-error`。
- 显示分支调用 `fetchHarborZones()`，只接受 `code === 200` 的响应；非 200 响应发出 `'error'` 并返回 `request-error`，该分支中请求或画布替换抛出的异常也由统一 `catch` 映射为 `request-error`。
- 规范化后没有可用区域时返回 `empty`；地图替换失败映射为 `empty` 或 `render-error`，成功时发出 `'visible'` 并返回画布报告的数量。
- 组件测试入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。

### 电子围栏数据规范化

- 真实入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。
- 仅处理 `enabled === '0'` 且去除首尾空白后非空的 `zone_id`；不符合条件时返回 `null`。
- `points` 按 `_` 分段、按 `,` 解析数值，只保留长度为 2 且两个值均为有限数的坐标对。
- 变更后的实现要求至少 4 个有效坐标点；少于 4 个时返回 `null`，满足条件时输出 `{ id, coordinates }` 形式的 `MapZoneModel`。
- adapter 测试入口：`apps/harbor-system/src/components/harbor-map/adapters/__tests__/normalize-zone.spec.ts`。

### 电子围栏数据获取

- 真实入口：`apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones`。
- 返回 `Promise<HarborApiResponse>`，其中响应包含数值 `code` 和 `HarborZoneDto[]` 数据。
- HarborMap 只把 `code === 200` 视为可进入规范化阶段的响应；该 service 不拥有地图渲染和状态事件责任。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 透传给地图画布的初始缩放级别 |

### Emits

| 名称 | 载荷 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏成功显示、成功隐藏或请求/渲染错误 |

`empty` 与 `superseded` 只通过 Expose 方法结果返回，不发出 `zoneStatusChange`。

### Slots

| 名称 | Slot Props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的工具栏内容 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 可能为：成功及数量、`empty`、`request-error`、`render-error` 或 `superseded`。

## 直接公共依赖

| Provider | 使用的公开契约 | 模块内吸收位置 |
| --- | --- | --- |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapZoneModel` | `normalizeZone()` 的成功输出 |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapCanvasExpose.replaceZones()`、`clearZones()` | `setZonesVisible()` 的显示和隐藏分支 |

HarborMap 只记录 fixture 中可由公开声明确认的地图区域模型、Expose 命令及命令结果，不拥有 provider 的内部渲染实现。

## 数据转换与责任分层

1. `fetchHarborZones()` 提供包含 `HarborZoneDto[]` 的接口响应。
2. `normalizeZone()` 过滤不可用 DTO、解析有限坐标并执行至少 4 个有效边界点的门槛，生成 `MapZoneModel | null`。
3. `setZonesVisible()` 移除 `null` 项；空集合在模块内终止为 `empty`，非空集合交给 `replaceZones()`。
4. 地图画布命令结果由 HarborMap 映射为公开的 `HarborZoneResult` 和必要的 `zoneStatusChange` 事件。

## 问题排查与症状索引

| 症状或稳定信号 | 第一检查点 | 下一验证入口 |
| --- | --- | --- |
| `setZonesVisible(true)` 返回 `empty` | 检查 `normalizeZone()` 是否因 `enabled`、空 `zone_id`、无效坐标或少于 4 个有效点过滤全部数据 | `adapters/__tests__/normalize-zone.spec.ts` |
| 返回 `request-error` 并发出 `'error'` | 检查非 200 `code`，以及显示分支中 `fetchHarborZones()` 或 `replaceZones()` 抛出的异常 | `__tests__/HarborMap.spec.ts` 中的组件编排入口 |
| 返回 `render-error` | 检查画布引用是否缺失、隐藏分支 `clearZones()` 是否抛出，或 `replaceZones()` 是否返回 `render-error`；画布引用缺失时不会发出 `'error'` | `__tests__/HarborMap.spec.ts` 的 `MapCanvas` stub 边界 |
| 返回 `superseded` | 检查该调用完成时的 `requestVersion` 是否已落后 | `__tests__/HarborMap.spec.ts` 的最新请求预期 |

这些返回状态和事件是稳定的模块内信号，只定位首个责任边界，不单独证明根因。

## 跨功能风险

- 有效边界点门槛同时影响 adapter 输出、显示分支的 `empty` 结果、画布是否收到 `replaceZones()` 调用，以及组件测试中的围栏样例。
- `requestVersion` 在显示和隐藏命令之间共享；任何新增异步阶段都需要在提交副作用前保持最新版本检查，否则旧调用可能覆盖新调用结果。
- `MapCanvasExpose` 的命令结果若扩展，HarborMap 的 `HarborZoneResult`、事件映射和验证范围需要同步核对。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| adapter | `apps/harbor-system/src/components/harbor-map/adapters/__tests__/normalize-zone.spec.ts` | 单元 | 四个有效点产生地图区域模型、三个有效点产生 `null` 的预期 | 请求编排、画布替换和组件事件 | DTO 解析格式或地图区域模型契约变化 | Vitest 能加载模块 TypeScript |
| 组件契约与交互 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 隐藏不发请求、最新请求语义以及 Props、Emits、Slots、Expose 的预期 | 真实接口和真实地图画布的集成行为 | service、共享画布或跨 owner 契约变化 | Vue Test Utils、Vitest 与 MapCanvas stub 可用 |
| 跨 owner 地图契约 | `packages/shared-ui/src/map-canvas/public.ts` 与 HarborMap 类型检查入口 | 类型 | HarborMap 使用的 `MapZoneModel`、`MapCanvasExpose` 签名可兼容 | 地图区域的视觉呈现和运行时交互 | 共享 UI 公开类型或导出路径变化 | owner 工程能解析 `@shared/ui/map-canvas` |

## 模块内事实冲突

- 变更后的 `normalizeZone()` 在有效坐标少于 4 个时返回 `null`，新增的 `adapters/__tests__/normalize-zone.spec.ts` 也以四点为预期边界。
- 现有 `HarborMap.spec.ts` 的“只保留最新显示请求结果”样例仍向最新请求提供 3 个有效点，并期待 `success` 与一次 `replaceZones()` 调用；按变更后的 adapter 分支，该样例会进入 `empty` 路径。
- 在该组件测试样例与四点规则对齐前，它不能作为四点规则下成功渲染链路的证明入口；本文档不把其三点成功预期记录为当前实现契约。

## 文档维护信息

- 文档位置：`apps/harbor-system/claudedocs/modules/HarborMap.md`。
- owner：`apps/harbor-system`。
- 核心入口、公开契约、直接公共依赖、验证入口或有效边界点规则变化时更新本文档。
- 调用方页面、共享地图画布内部实现和单次验证执行状态不写入本文档。
