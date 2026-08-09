---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: "HarborMap"
module_type: "component"
owner: "apps/harbor-system"
audience: ai
read_mode: progressive
depth: "detailed"
summary: "HarborMap 对外提供电子围栏显隐命令，负责获取和规范化港区围栏，并把绘制与清除委托给共享地图画布。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  zone_fetch:
    entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones
    body_section: 围栏数据获取

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  diagnostics: 问题排查与症状索引
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-09"
last_updated_by: doc-gen
---

# HarborMap - 港区电子围栏地图组件

## 模块概述

`HarborMap` 包装共享 `MapCanvas`，将港区围栏服务返回的 DTO 转换为地图围栏模型，并通过公开的 `setZonesVisible()` 命令完成显示或隐藏。组件使用单调递增的请求版本号淘汰过期异步结果，并通过返回值和 `zoneStatusChange` 事件向外提供当前命令结果。

## 模块边界

| 路径 | 角色 | 当前职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 公开契约、显隐编排、请求版本淘汰、事件和结果映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 围栏 DTO、公开命令结果和 Expose 类型 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 提供港区围栏获取入口；当前实现返回空数据的成功响应 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 将港区 DTO 校验并转换为共享地图围栏模型 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 记录组件公开接口、隐藏路径和并发淘汰的稳定验证入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 提供本模块实际使用的地图围栏模型与画布命令公开类型 |

调用 `HarborMap` 的页面和其状态、失败回退或交互实现不属于本模块边界。

## 功能目录

### 电子围栏显隐编排

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 每次调用先递增 `requestVersion`，后续异步阶段只接受仍为最新版本的结果。
- 隐藏命令不请求围栏数据，而是调用 `MapCanvasExpose.clearZones()`；清除完成且命令仍为最新时，发出 `zoneStatusChange: hidden` 并返回 `{ status: 'success', count: 0 }`。
- 显示命令依次调用 `fetchHarborZones()`、使用 `normalizeZone()` 过滤和转换数据，再调用 `MapCanvasExpose.replaceZones()`。
- 地图引用不存在时返回 `render-error`。非 200 响应或请求阶段异常映射为 `request-error`；没有有效围栏映射为 `empty`；已被更新命令取代的异步结果映射为 `superseded`。
- 仅成功绘制时发出 `visible`，成功清除时发出 `hidden`；明确错误分支发出 `error`。返回 `empty`、`superseded` 或地图引用缺失时不必然发出事件，具体映射见状态矩阵。

验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 覆盖隐藏时不请求数据，以及两个显示请求只提交最新结果的预期。

### 围栏数据规范化

入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`

- 输入为 `HarborZoneDto`，只有 `enabled === '0'` 且去除首尾空白后的 `zone_id` 非空时继续转换。
- `points` 使用下划线分隔坐标点，单个坐标点使用逗号分隔并转换为数字。
- 仅保留恰好包含两个有限数值的坐标点；有效坐标少于 3 个时返回 `null`。
- 成功结果为 `{ id: dto.zone_id, coordinates }`，其中 `id` 保留原始 `zone_id` 字符串，坐标满足 `MapZoneModel` 公开结构。

该适配器返回的 `null` 会在显示编排中被过滤；过滤后没有围栏时，公开命令返回 `empty`，不会调用 `replaceZones()`。

### 围栏数据获取

入口：`apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones`

- 返回 `Promise<HarborApiResponse>`，响应包含数值 `code` 和 `HarborZoneDto[]` 类型的 `data`。
- 显示编排只把 `code === 200` 视为可进入转换阶段的响应。
- 当前服务实现直接返回 `{ code: 200, data: [] }`，没有声明外部请求客户端或其他公共依赖。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 透传给 `MapCanvas` 的初始缩放级别 |

### Emits

| 名称 | 负载 | 发出条件 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 最新显示命令绘制成功时发出 `visible`；最新隐藏命令清除成功时发出 `hidden`；请求、清除或绘制的明确错误分支发出 `error` |

### Slots

| 名称 | Props | 位置 |
| --- | --- | --- |
| `toolbar` | 无 | 位于地图画布之前的工具栏区域 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 当前可能为：

- `{ status: 'success', count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 直接公共依赖

`packages/shared-ui/src/map-canvas/public.ts` 是跨 owner 的直接公共契约来源。本模块只依赖以下最小表面：

| Provider symbol | 本模块实际使用 |
| --- | --- |
| `MapZoneModel` | `normalizeZone()` 的成功输出；包含 `id: string` 和 `coordinates: Array<[number, number]>` |
| `MapCanvasExpose.replaceZones` | 接收规范化后的 `MapZoneModel[]`，返回 `success`、`empty` 或 `render-error` |
| `MapCanvasExpose.clearZones` | 隐藏命令中清除地图围栏，返回 `Promise<void>` |

本模块不拥有共享地图画布的绘制实现，也不扩展记录其未被实际使用的契约。

## 数据转换与责任分层

显示链路：

1. `fetchHarborZones()` 产生 `{ code, data: HarborZoneDto[] }`。
2. `setZonesVisible(true)` 检查响应码和请求版本。
3. `normalizeZone()` 将每个 DTO 校验并转换为 `MapZoneModel | null`。
4. 显示编排过滤 `null`，把非空 `MapZoneModel[]` 交给 `replaceZones()`。
5. 共享地图命令结果被吸收为 `HarborZoneResult`，组件再按分支发出可选状态事件。

隐藏链路不经过服务和适配器，直接由 `setZonesVisible(false)` 调用 `clearZones()` 并映射公开结果。

## 状态与错误责任矩阵

| 场景 | 返回结果 | `zoneStatusChange` |
| --- | --- | --- |
| 地图画布引用不存在 | `render-error` | 无 |
| 最新隐藏命令清除成功 | `success`, `count: 0` | `hidden` |
| 隐藏命令清除后已过期 | `superseded` | 无 |
| 清除抛出异常 | `render-error` | `error` |
| 显示请求在响应后已过期 | `superseded` | 无 |
| 服务响应码不是 200 | `request-error` | `error` |
| 规范化后没有有效围栏 | `empty` | 无 |
| 绘制完成后命令已过期 | `superseded` | 无 |
| `replaceZones()` 返回 `empty` | `empty` | `error` |
| `replaceZones()` 返回 `render-error` | `render-error` | `error` |
| 最新显示命令发生请求阶段异常 | `request-error` | `error` |
| 最新显示命令绘制成功 | `success`, `count` 来自画布结果 | `visible` |

## 问题排查与症状索引

| 症状或结果 | 第一检查点 | 稳定信号 | 下一验证入口 |
| --- | --- | --- | --- |
| `empty` 且未调用绘制 | `normalizeZone()` 的过滤条件 | `enabled` 必须为字符串 `'0'`、`zone_id` 非空、有效坐标至少 3 个 | `HarborMap.spec.ts` 仅覆盖有效数据链路；模块内没有独立适配器边界用例 |
| `request-error` | `fetchHarborZones()` 的响应码或异常 | 只有 `code === 200` 进入转换阶段 | `HarborMap.spec.ts`；模块内部测试未覆盖请求错误分支 |
| `render-error` | `mapCanvasRef` 和共享画布命令结果 | 引用缺失、清除异常或绘制返回 `render-error` 都会映射到该结果 | `HarborMap.spec.ts` 的 MapCanvas stub 交互用例 |
| `superseded` | `requestVersion` 是否被后续命令递增 | 过期显示结果不会提交给地图；清除完成和绘制完成后也会检查版本 | `HarborMap.spec.ts` 的最新请求保留用例 |
| 返回 `empty` 同时发出 `error` | `replaceZones()` 的结果分支 | 画布返回 `empty` 时组件先发出 `error`，再返回 `empty` | `HarborMap.spec.ts`；模块内部测试未覆盖画布 `empty` 分支 |

第一检查点用于定位责任边界，不等同于根因结论。

## 跨功能风险

- `requestVersion` 同时约束显示请求、隐藏清除和地图绘制的结果提交；修改任一异步阶段时必须保持“只有最新命令可提交成功结果”的不变量。
- 隐藏命令的 `clearZones()` 异常分支不会再次检查 `requestVersion`，因此较早隐藏命令在较晚命令开始后仍可能发出 `error`。
- `normalizeZone()` 对启用值使用精确字符串 `'0'`，并保留未裁剪的原始 `zone_id` 作为地图 id；调整上游 DTO 语义时需要同步核对过滤与身份语义。
- 组件把共享画布的 `empty` 映射为公开 `empty`，同时发出 `error`；返回结果与事件不是一一同名映射，使用或修改契约时应分别核对。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件公开契约与隐藏交互 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | `initialZoom`、`toolbar`、Expose 可访问，以及隐藏命令不请求数据、调用清除并发出 `hidden` 的预期 | 共享地图真实渲染、所有异常分支和外部调用方行为 | Props、Emits、Slots、Expose 或 MapCanvas 交互变化时扩充组件用例 |
| 并发显示与有效 DTO 链路 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | 两个并发展示请求只把最新有效 DTO 响应提交给 `replaceZones()`，旧请求预期返回 `superseded` | 显示与隐藏交错、绘制完成后的淘汰、无效 DTO 边界和异常竞态 | 修改版本推进点、DTO 规则或新增异步阶段时扩充相应组件或适配器用例 |

模块内部没有独立覆盖 `normalizeZone()` 边界输入、真实 service 集成、共享画布实际绘制，以及请求、清除和绘制错误矩阵的验证入口。跨 owner 的 `MapZoneModel` 或 `MapCanvasExpose` 契约变化需要扩大到 `packages/shared-ui` 的类型与集成验证范围。

## 文档维护信息

- 事实入口：`HarborMap.vue`、`types.ts`、`services/harbor-api.ts`、`adapters/normalize-zone.ts`。
- 验证导航：`__tests__/HarborMap.spec.ts` 只用于记录稳定预期和覆盖范围。
- 直接公共依赖入口：`packages/shared-ui/src/map-canvas/public.ts`。
- 维护边界：只记录 `HarborMap` 自有事实和真实使用的最小共享契约；调用方页面及其状态、回退和测试始终排除。
