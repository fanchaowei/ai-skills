---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 通过公开组件契约编排港区电子围栏的查询、规范化、显隐渲染与受限区域高亮入口。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  restricted_zone_highlight:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#highlightRestrictedZone
    body_section: 受限区域高亮入口

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港区电子围栏组件

## 模块概述

HarborMap 是 `apps/harbor-system` 拥有的 Vue 组件模块。它向外提供电子围栏显隐与受限区域高亮命令，负责请求港区围栏、把接口 DTO 转换为地图模型、调用共享地图画布渲染或清除围栏，并以结构化结果和事件公开命令结果。

## 模块边界

| 路径 | 角色 | 模块内职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 公开契约、命令编排、并发淘汰、地图调用与事件发射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 港区 DTO、命令结果联合类型与 Expose 接口 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | `fetchHarborZones()` 请求边界及响应类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 港区围栏 DTO 到共享地图模型的过滤与转换 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块公开契约、显隐编排和并发语义的稳定验证入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | HarborMap 实际使用的地图模型与画布命令公开声明 |

模块止于 HarborMap 的公开组件契约和上述专属实现。共享地图画布的内部渲染实现不属于本模块。

## 功能目录

### 电子围栏显隐编排

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 每次调用先递增模块级 `requestVersion`，仅允许当前最新命令继续提交异步结果。
- `visible` 为 `false` 时直接调用 `MapCanvasExpose.clearZones()`，不请求围栏数据；清除成功后发射 `zoneStatusChange: hidden`，返回 `{ status: 'success', count: 0 }`。
- `visible` 为 `true` 时调用 `fetchHarborZones()`。响应码不是 `200` 时发射 `zoneStatusChange: error` 并返回 `request-error`。
- 成功响应中的每个 DTO 交给 `normalizeZone()`；无效或不满足模块筛选条件的记录被过滤。没有可渲染结果时返回 `empty`。
- 有效地图模型交给 `MapCanvasExpose.replaceZones()`。画布成功后发射 `zoneStatusChange: visible` 并返回成功数量；画布的 `empty` 映射为模块 `empty`，其他非成功结果映射为 `render-error`。
- 请求、清除或渲染完成时，如果该命令已不是最新版本，则返回 `superseded`，不提交过期的成功事件或渲染结果。

最小事实链：

`setZonesVisible()` → `requestVersion` → `fetchHarborZones()` / `clearZones()` → `normalizeZone()` → `replaceZones()` → `HarborZoneResult` 与 `zoneStatusChange` → `HarborMap.spec.ts`

### 受限区域高亮入口

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#highlightRestrictedZone`

- `highlightRestrictedZone(id)` 是公开 Expose 命令，返回 `Promise<HarborZoneResult>`。
- 当前实现直接委托 `setZonesVisible(true)`，因此复用围栏请求、规范化、渲染、事件和并发淘汰语义。
- `id` 参数当前不参与请求、过滤或地图命令；该契约只保证触发可见围栏渲染，不保证仅选择或突出指定 id 的围栏。

最小事实链：

`highlightRestrictedZone()` → `setZonesVisible(true)` → 围栏请求与规范化 → `replaceZones()` → `HarborZoneResult` → `HarborMap.spec.ts`

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 作为 `initial-zoom` 传给内部 `MapCanvas`。 |

### Emits

| 名称 | 载荷 | 发射条件 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏成功替换后发射 `visible`；成功清除后发射 `hidden`；请求、清除或渲染错误时发射 `error`。`empty` 与 `superseded` 不发射状态事件。 |

### Slots

| 名称 | Slot props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的工具区域。 |

### Expose

| 名称 | 签名 | 语义 |
| --- | --- | --- |
| `setZonesVisible` | `(visible: boolean) => Promise<HarborZoneResult>` | 显示时请求、转换并替换围栏；隐藏时清除围栏。 |
| `highlightRestrictedZone` | `(id: string) => Promise<HarborZoneResult>` | 当前委托 `setZonesVisible(true)`；接收 `id`，但不提供按 id 筛选或单区高亮保证。 |

`HarborZoneResult` 的公开结果为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 直接公共依赖

| Provider | HarborMap 使用的公开契约 | 模块内吸收位置 |
| --- | --- | --- |
| `@shared/ui/map-canvas/public` | `MapZoneModel`：`id` 与坐标数组；`MapCanvasExpose.replaceZones(zones)`；`MapCanvasExpose.clearZones()`；地图命令的 `success`、`empty`、`render-error` 结果 | `normalize-zone.ts#normalizeZone` 生成模型；`HarborMap.vue#setZonesVisible` 调用清除与替换命令并映射结果 |

HarborMap 只依赖这些公开声明；共享地图画布如何绘制、存储或清理图形不进入本模块事实。

## 数据转换与责任分层

1. `fetchHarborZones()` 返回 `{ code, data: HarborZoneDto[] }`；`HarborZoneDto` 使用 `zone_id`、字符串标记 `enabled` 和下划线分隔的 `points`。
2. `normalizeZone()` 只接受 `enabled === '0'` 且 `zone_id` 非空的记录，把 `points` 拆为有限数值坐标；少于三个有效坐标时返回 `null`。
3. 有效记录转换为 `MapZoneModel { id, coordinates }`，由 `setZonesVisible()` 过滤掉 `null` 后交给 `replaceZones()`。
4. HarborMap 把请求与地图画布的结果吸收为 `HarborZoneResult`，并仅在可见、隐藏或错误状态需要向外广播时发射 `zoneStatusChange`。

## 状态与错误责任矩阵

| 模块结果 | 触发条件 | 事件 |
| --- | --- | --- |
| `success` | 清除成功，或共享画布成功替换有效围栏 | `hidden` 或 `visible` |
| `empty` | 规范化后无有效围栏，或共享画布返回 `empty` | 无 |
| `request-error` | 接口响应码非 `200`，或可见流程中的请求/转换阶段抛错 | `error`；若抛错前命令已过期则返回 `superseded` 且不发射 |
| `render-error` | 画布引用不存在、清除抛错，或共享画布返回非成功且非 `empty` 的结果 | 画布引用不存在时无事件；其他渲染错误发射 `error` |
| `superseded` | 异步检查点发现 `currentVersion !== requestVersion` | 无 |

## 跨功能风险

- `setZonesVisible()` 与 `highlightRestrictedZone()` 共享同一个 `requestVersion`。后发命令会使先发但尚未完成的可见命令返回 `superseded`。
- `highlightRestrictedZone(id)` 的名称和参数表达单区目标，但当前实现不使用 `id`；模块契约不能被解释为按 id 过滤、选中或视觉强调。
- 画布引用缺失会直接返回 `render-error`，但不会发射 `zoneStatusChange: error`；该分支与其他渲染错误的事件语义不同。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| 组件契约、交互与命令编排 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | Vitest 组件测试 | 隐藏命令不请求数据并清除画布；并发显示命令只提交最新结果；`initialZoom`、`toolbar`、`zoneStatusChange`、`setZonesVisible` 的预期契约；`highlightRestrictedZone` 经公开 Expose 返回渲染结果的预期 | 真实接口、共享地图画布内部渲染、所有错误与空数据分支、按 `id` 选择单个围栏的行为 | `MapCanvasExpose` 跨 owner 契约变化、真实请求集成变化或新增 id 定向高亮语义时需要扩大到对应集成层 | 测试使用 Vue Test Utils、模拟 `fetchHarborZones()`，并以 stub 提供 `clearZones()` 与 `replaceZones()` |

## 文档维护信息

- 主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- Owner：`apps/harbor-system`
- 公开契约类型：`apps/harbor-system/src/components/harbor-map/types.ts#HarborMapExpose`
- 直接依赖声明：`packages/shared-ui/src/map-canvas/public.ts`
- 稳定验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`
- 当 Props、Emits、Slots、Expose、`HarborZoneResult`、并发淘汰语义、DTO 规范化规则或 `MapCanvasExpose` 使用方式变化时，同步维护本文档。
