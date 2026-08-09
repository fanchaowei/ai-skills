---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 负责港区电子围栏的查询、规范化、画布显隐编排以及结构化结果和状态事件输出。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  diagnostics: 问题排查与症状索引
  data_flow: 数据转换与责任分层
  risks: 跨功能风险

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港区电子围栏组件

## 模块概述

`HarborMap` 通过暴露方法接收围栏显隐命令。显示链路查询港区围栏、过滤并转换有效坐标、调用共享地图画布替换围栏，最后通过 Promise 结果和 `zoneStatusChange` 事件公开状态；隐藏链路清除画布围栏。

## 模块边界

| 路径 | 角色 | 模块内职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 公开契约、显隐编排、请求版本淘汰、结果与事件映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | DTO、公开结果联合类型和 Expose 接口 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 港区围栏查询入口及响应类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | DTO 有效性过滤与画布模型转换 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | `MapZoneModel`、`MapCanvasExpose` 和画布命令结果的最小公开契约 |

使用 `HarborMap` 的页面或其他组件属于 caller，不进入本模块边界；其 UI 状态、失败回退和测试不作为本模块事实。

## 功能目录

### 电子围栏显隐编排

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 每次命令递增 `requestVersion`；异步阶段完成后，旧版本返回 `{ status: 'superseded' }`。
- `visible = false` 时调用 `MapCanvasExpose.clearZones()`；当前命令仍有效时发出 `zoneStatusChange('hidden')`，并返回成功计数 `0`。
- `visible = true` 时调用 `fetchHarborZones()`；非 `200` 响应映射为 `request-error` 并发出 `error`。
- 有效围栏非空时调用 `MapCanvasExpose.replaceZones()`，将画布命令结果映射为 `HarborZoneResult`。
- 输入变化集中的事件顺序在画布命令完成前发出 `visible`。因此 `replaceZones()` 返回 `render-error` 时，公开 Promise 结果为 `render-error`，但事件流中已出现 `visible` 且该分支不再发出 `error`。

### 围栏数据规范化

入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`

- 只接受 `enabled === '0'` 且 `zone_id` 非空的 DTO。
- `points` 按 `_` 拆分点，再按 `,` 转为数值坐标。
- 非有限数值点被过滤；少于 3 个有效坐标时返回 `null`。
- 有效 DTO 转为共享画布使用的 `{ id, coordinates }`。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 传给地图画布的初始缩放级别 |

### Emits

| 名称 | 参数 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 发布围栏显隐或错误状态；输入变化集使 `visible` 可能早于画布替换结果出现 |

### Slots

| 名称 | 语义 |
| --- | --- |
| `toolbar` | 位于地图画布前的工具栏内容 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 可为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 数据转换与责任分层

```text
setZonesVisible(true)
  → fetchHarborZones(): HarborZoneDto[]
  → normalizeZone(): MapZoneModel | null
  → 过滤 null
  → MapCanvasExpose.replaceZones(MapZoneModel[])
  → HarborZoneResult + zoneStatusChange
```

- Service 层提供港区 DTO，不负责画布模型或 UI 状态。
- Adapter 层负责可渲染数据的结构转换和过滤，不负责画布命令结果。
- 组件编排层拥有请求版本、空数据、请求错误、画布错误以及公开事件的映射责任。
- 共享画布只通过公开命令结果暴露渲染边界；其内部渲染实现不属于本模块。

## 直接公共依赖

Provider：`packages/shared-ui/src/map-canvas/public.ts`

模块实际使用的最小契约：

- `MapZoneModel`：围栏 `id` 与坐标数组。
- `MapCanvasExpose.replaceZones(zones)`：返回 `success`、`empty` 或 `render-error`。
- `MapCanvasExpose.clearZones()`：异步清除围栏。

## 问题排查与症状索引

### 症状：围栏渲染失败，但状态观察者仍收到已显示

| 导航项 | 稳定入口或信号 |
| --- | --- |
| 第一检查点 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` 中 `zoneStatusChange('visible')`、`await mapCanvas.replaceZones(zones)`、版本检查和结果映射四者的相对顺序 |
| 稳定结构化信号 | 同一请求版本下，`replaceZones()` 返回 `{ status: 'render-error' }`，`setZonesVisible(true)` 返回 `{ status: 'render-error' }`，同时 emit 记录包含 `zoneStatusChange('visible')` 且不包含该分支的 `zoneStatusChange('error')` |
| 故障边界 | 上述信号组合将故障限定在 `HarborMap` 对画布结果与公开事件的状态映射；此时不需要读取 caller 状态，也不能据此推断 `MapCanvas` 内部根因 |
| 下一验证入口 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 的组件级 `setZonesVisible(true)` 场景：提供非空有效 DTO，令 `replaceZones()` 返回 `render-error`，同时观察 Promise 结果和 `zoneStatusChange` 事件序列 |

边界分流：

- 若 `replaceZones()` 没有返回 `render-error`，先在 `MapCanvasExpose` 命令边界核对实际结构化结果。
- 若 Promise 结果为 `render-error` 但没有出现 `visible`，本症状的模块内稳定信号不成立；应从模块外的状态消费边界继续定位，但 caller 事实不写入本文档。
- 一旦已确认有效围栏非空并进入 `replaceZones()`，查询响应码和 `normalizeZone()` 不再是“失败但仍显示”的第一检查点。

## 跨功能风险

- `zoneStatusChange` 与 `HarborZoneResult` 是同一命令的两条公开状态通道。事件在异步画布结果前发布时，渲染失败和请求淘汰都可能让两条通道表达不同状态。
- `visible` 只能作为组件已发布的状态信号，不能单独证明画布已经成功替换围栏；画布命令结果是渲染边界的稳定结构化信号。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| adapter | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` 的模块内部单元入口 | 单元 | DTO 过滤、坐标解析和 `MapZoneModel` 转换预期 | 真实 API 数据质量、画布渲染 | DTO 结构或共享模型变化 | 使用有限数值坐标和最少 3 点的固定样本 |
| 组件状态映射 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 请求、画布命令结果、Expose 返回值、emit 序列和版本淘汰之间的预期映射 | 共享画布内部是否实际绘制、caller 如何呈现事件 | `MapCanvasExpose` 或事件契约变化 | 可稳定替换 API 与 `MapCanvasExpose` 命令结果 |
| 跨 owner 画布契约 | `packages/shared-ui/src/map-canvas/public.ts` 与 HarborMap 组件场景 | 类型、组件或集成 | HarborMap 使用的命令签名和结果联合类型兼容性 | 真实地图引擎、浏览器图层视觉结果 | 共享画布结果语义或渲染引擎变化 | provider 公开声明保持可用 |

针对本症状，下一入口应同时断言 Promise 结果和 emit 序列；只观察其中一条状态通道无法覆盖两者不一致的边界。

## 文档维护信息

- Owner：`apps/harbor-system`
- 核心入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`
- 公开依赖入口：`packages/shared-ui/src/map-canvas/public.ts`
- 诊断导航在事件时序、结果映射、Expose/Emits 契约或 `MapCanvasExpose` 结果语义变化时需要同步核对。
