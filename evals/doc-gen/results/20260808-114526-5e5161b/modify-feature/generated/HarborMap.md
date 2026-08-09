---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: complex-module
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 编排电子围栏的查询、有效性转换、并发淘汰以及地图渲染与清理，并通过 Vue 公开契约返回稳定结果。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 电子围栏数据规范化
  request_supersession:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 请求淘汰与结果状态
  map_rendering:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 地图渲染与清理

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  diagnostics: 问题排查与状态责任
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 电子围栏地图模块

## 模块概述

HarborMap 是 `apps/harbor-system` 内的复杂 Vue 模块。它通过公开方法接收围栏显隐意图，查询电子围栏 DTO，将有效数据转换为共享地图模型，并调用地图画布完成替换或清理；模块同时负责把请求、渲染、空数据和并发淘汰结果收敛为 `HarborZoneResult`。

## 模块边界

| 路径 | 角色 | 当前职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 公开契约、显隐编排、并发版本控制、结果与事件映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | API DTO、公开结果联合类型和 Expose 接口 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 围栏查询入口与 `HarborApiResponse` |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | DTO 有效性过滤与地图模型转换 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 组件公开契约、隐藏分支和可见请求淘汰的预期入口 |
| `apps/harbor-system/src/components/harbor-map/adapters/__tests__/normalize-zone.spec.ts` | owned | 四个有效边界点规则的预期入口 |

`packages/shared-ui/src/map-canvas/public.ts` 是直接公共依赖，只吸收 HarborMap 真实使用的地图模型与 Expose 契约。模块边界不沿组件调用方向扩展。

## 功能目录

### 电子围栏显隐编排

入口为 `setZonesVisible(visible)`：

- 每次调用先递增 `requestVersion` 并捕获本次版本；地图引用不存在时直接返回 `{ status: 'render-error' }`。
- `visible=false` 时不查询围栏，调用 `clearZones()`；成功后发出 `zoneStatusChange('hidden')`，并返回 `{ status: 'success', count: 0 }`。
- `visible=true` 时调用 `fetchHarborZones()`；响应 `code` 不是 `200` 时发出 `zoneStatusChange('error')` 并返回 `{ status: 'request-error' }`。
- 响应数据逐项经过 `normalizeZone()`，无有效围栏时返回 `{ status: 'empty' }`，不调用 `replaceZones()`。
- 有有效围栏时调用 `replaceZones()`，再把地图结果映射为模块公开结果和 `zoneStatusChange` 事件。

最短事实链为：`setZonesVisible` → `requestVersion` 与查询/清理编排 → `normalizeZone` → `MapCanvasExpose` → `HarborZoneResult` → `HarborMap.spec.ts`。

### 电子围栏数据规范化

`normalizeZone(dto)` 当前实现按以下顺序转换数据：

1. 只接受 `enabled === '0'` 且去除首尾空白后非空的 `zone_id`。
2. 以 `_` 分隔点、以 `,` 分隔坐标，并把坐标转换为数字。
3. 丢弃不是两个数值或包含非有限数值的点。
4. 按变化集实现，少于四个有效坐标时返回 `null`；达到四个或更多有效坐标时返回 `{ id, coordinates }`。

该门槛描述当前生产实现；它与一个既有组件测试样例的稳定预期不一致，见“模块内事实冲突”。

最短事实链为：`HarborZoneDto` → `normalizeZone` → 有效点过滤与数量门槛 → `MapZoneModel | null` → `normalize-zone.spec.ts`。

### 请求淘汰与结果状态

`requestVersion` 是模块级递增版本号。可见请求在查询完成、地图替换完成以及异常收敛时检查版本；隐藏请求在清理成功后检查版本。检查发现已有更新调用时，旧调用返回 `{ status: 'superseded' }`，且不发出成功事件。

隐藏分支的 `clearZones()` 异常路径不再次检查版本，直接发出 `zoneStatusChange('error')` 并返回 `{ status: 'render-error' }`。因此“旧请求淘汰”不能扩展解释为所有隐藏异常都会被静默淘汰。

最短事实链为：`setZonesVisible` → `requestVersion` → 异步阶段后的版本比较 → `superseded` 或当前结果 → `HarborMap.spec.ts`。

### 地图渲染与清理

- 隐藏围栏使用 `MapCanvasExpose.clearZones()`。
- 显示围栏使用 `MapCanvasExpose.replaceZones(zones)`，其中 `zones` 是规范化后的 `MapZoneModel[]`。
- `replaceZones()` 返回 `success` 时，模块发出 `zoneStatusChange('visible')` 并透传 `count`。
- `replaceZones()` 返回 `empty` 或 `render-error` 时，模块发出 `zoneStatusChange('error')`，分别返回模块的 `empty` 或 `render-error`。
- 可见流程中的异常在仍为最新请求时被收敛为 `request-error`；若异常发生后该调用已过期，则返回 `superseded`。

最短事实链为：`setZonesVisible` → 有效围栏集合 → `clearZones`/`replaceZones` → 事件与 `HarborZoneResult` → `HarborMap.spec.ts`。

## 当前公开契约

| 类别 | 公开项 | 语义 |
| --- | --- | --- |
| Props | `initialZoom?: number` | 默认值为 `12`；模板将该值传给地图画布的 `initial-zoom` |
| Emits | `zoneStatusChange(status)` | `status` 为 `'visible' | 'hidden' | 'error'`；成功显示或隐藏，以及 API、清理或地图命令的显式错误分支时发出；地图引用缺失、规范化为空和请求淘汰不发出 |
| Slots | `toolbar` | 命名 slot，渲染在地图画布之前 |
| Expose | `setZonesVisible(visible: boolean): Promise<HarborZoneResult>` | 请求显示或隐藏围栏，并返回结构化结果 |

`HarborZoneResult` 的公开分支为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 直接公共依赖

| Provider | HarborMap 实际使用的公开项 | 模块内吸收位置 |
| --- | --- | --- |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapZoneModel` 的 `id`、`coordinates` | `normalizeZone()` 的成功输出 |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapCanvasExpose.replaceZones(zones)` | 显示围栏时替换地图数据 |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapCanvasExpose.clearZones()` | 隐藏围栏时清理地图数据 |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapZoneCommandResult` 的 `success`、`empty`、`render-error` 语义 | 映射为 `HarborZoneResult` 和事件 |

共享公开声明未描述地图组件的 `initialZoom` Prop；本文档只记录 HarborMap 模板确实传入该属性，不扩写 provider 的未提供契约。

## 数据转换与责任分层

1. `fetchHarborZones()` 提供 `{ code, data: HarborZoneDto[] }`；当前 service 实现返回 `code: 200` 和空数组。
2. `normalizeZone()` 负责业务有效性与字符串坐标解析，输出 `MapZoneModel | null`。
3. `HarborMap.vue` 过滤 `null`，决定空结果、请求淘汰和是否进入地图渲染。
4. 地图画布负责替换或清理围栏，并通过 `MapZoneCommandResult` 返回渲染结果。
5. HarborMap 把上游与地图结果收敛为 `HarborZoneResult`，必要时发出 `zoneStatusChange`。

## 问题排查与状态责任

| 结构化结果或症状 | 第一检查点 | 模块内责任 | 下一验证入口 |
| --- | --- | --- | --- |
| `empty` 且未调用地图替换 | `response.data.map(normalizeZone)` 的有效结果数量 | DTO 过滤或四点门槛后没有有效围栏 | `adapters/__tests__/normalize-zone.spec.ts` |
| `request-error` | API `code` 与可见流程的异常入口 | 非 `200` 响应或可见流程异常的结果映射 | `__tests__/HarborMap.spec.ts` 与 `services/harbor-api.ts` |
| `render-error` | `mapCanvasRef`、`clearZones()` 或地图命令结果 | 地图引用缺失、清理异常或地图明确返回渲染错误 | `__tests__/HarborMap.spec.ts` 与地图公开契约 |
| `superseded` | 当前调用捕获的版本与 `requestVersion` | 较旧调用的结果淘汰 | `__tests__/HarborMap.spec.ts` |
| `empty` 同时发出 `error` | `replaceZones()` 是否返回 `empty` | 地图返回的空结果会映射为空结果并发出错误事件 | `__tests__/HarborMap.spec.ts` 与地图公开契约 |

第一检查点和结构化结果仅用于定位责任层，不代表根因。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| adapter 规则 | `apps/harbor-system/src/components/harbor-map/adapters/__tests__/normalize-zone.spec.ts` | 单元 | 三个有效点返回 `null`、四个有效点生成地图模型的预期 | 本次测试执行结果、组件编排或地图渲染 | DTO 格式、有效性字段或地图模型变化 |
| 组件显隐与并发 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 隐藏不发起查询、可见请求淘汰、Props/Emits/Slots/Expose 的预期覆盖 | 四点门槛与现有三点成功样例已经一致、本次执行结果 | 状态联合类型、并发检查点或事件语义变化 |
| 共享地图契约 | `packages/shared-ui/src/map-canvas/public.ts` | 类型契约核对 | HarborMap 使用的地图模型与 Expose 方法形状 | 地图 provider 的内部渲染行为 | `MapZoneModel`、`MapCanvasExpose` 或命令结果变化 |

## 模块内事实冲突

- 更新后的 `normalizeZone()` 实现要求至少四个有效边界点；`adapters/__tests__/normalize-zone.spec.ts` 也把“三点无效、四点有效”作为预期。
- `__tests__/HarborMap.spec.ts` 的“保留最新可见请求结果”样例仍给最新围栏提供三个有效点，并预期返回 `{ status: 'success', count: 1 }` 且调用一次 `replaceZones()`。
- 按更新后的生产实现，该三点样例会在规范化后得到空集合，返回 `{ status: 'empty' }`，不会调用 `replaceZones()`。因此四点规则与该组件测试的稳定预期尚未统一；测试入口不能证明两者当前一致。

## 文档维护信息

- 文档 owner：`apps/harbor-system`。
- 核心维护入口：`HarborMap.vue#setZonesVisible`、`normalize-zone.ts#normalizeZone`、`types.ts#HarborZoneResult`。
- 当 Vue 四类公开契约、围栏有效性规则、结果联合类型、并发检查点或共享地图公开契约变化时，需要同步核对本文档。
- 验证章节只描述稳定入口与证明范围，不记录单次执行状态。
