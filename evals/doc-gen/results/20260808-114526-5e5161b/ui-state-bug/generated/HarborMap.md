---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 编排港区电子围栏的查询、规范化、地图显隐、并发淘汰与状态事件。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  latest_request_wins:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#requestVersion
    body_section: 最新请求优先

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

# HarborMap - 港区电子围栏地图组件

## 模块概述

`HarborMap` 对外提供电子围栏显隐命令，对内完成围栏查询、数据规范化、地图命令调用、并发结果淘汰与状态事件发送。组件使用共享 `MapCanvas` 的公开类型和暴露方法，但不拥有共享画布的渲染实现。

## 模块边界

| 路径或范围 | 角色 | 边界依据 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 组件入口，拥有显隐编排、事件发送和请求版本状态 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 定义组件专属 DTO、命令结果和 Expose 接口 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 组件专属围栏查询入口 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 将组件专属 DTO 转换为地图公开模型 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块内部组件验证入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 提供本模块真实使用的 `MapZoneModel`、`MapCanvasExpose` 和地图命令结果 |
| 页面及其他组件使用者 | caller | 只通过 HarborMap 公开契约调用本模块，无条件排除其状态、回退和测试 |

边界明确，无需用户确认。模块类型为 Vue 组件；因包含组件、专属 service、adapter、类型、异步状态和模块测试，采用 detailed 粒度。

## 功能目录

### 电子围栏显隐编排

入口为 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。

- 每次调用先递增 `requestVersion`，并读取当前 `MapCanvasExpose`；画布引用不存在时直接返回 `{ status: 'render-error' }`。
- `visible` 为 `false` 时只调用 `clearZones()`，不查询围栏。当前调用仍为最新时发送 `zoneStatusChange: hidden`，并返回 `{ status: 'success', count: 0 }`；清除抛错时发送 `error` 并返回 `render-error`。
- `visible` 为 `true` 时调用 `fetchHarborZones()`。非 `200` 响应发送 `error` 并返回 `request-error`。
- 有效 DTO 经 `normalizeZone()` 转换并过滤；结果为空时返回 `empty`，不调用 `replaceZones()`。
- 对非空结果，当前实现先发送 `zoneStatusChange: visible`，再等待 `replaceZones(zones)`。
- `replaceZones()` 返回 `success` 时，组件返回地图提供的 `count`。
- `replaceZones()` 返回 `empty` 时，组件随后发送 `error` 并返回 `empty`。
- `replaceZones()` 返回 `render-error` 时，组件返回 `render-error`，但不发送纠正性的 `error`；本次事件流只保留此前的 `visible`。
- 显示链路中抛出的异常在请求仍为最新时发送 `error` 并返回 `request-error`。

最小事实链：`setZonesVisible` → `requestVersion` → `fetchHarborZones` / `clearZones` → `normalizeZone` → `MapCanvasExpose.replaceZones` / `clearZones` → `HarborZoneResult` 与 `zoneStatusChange` → `HarborMap.spec.ts`。

### 围栏数据规范化

入口为 `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。

- 仅接受 `enabled === '0'` 且 `zone_id` 去空白后非空的 DTO。
- `points` 以 `_` 分割点、以 `,` 分割坐标，并将两个有限数值组成 `[number, number]`。
- 少于三个有效坐标点时返回 `null`；否则返回 `{ id, coordinates }` 形式的 `MapZoneModel`。
- `setZonesVisible(true)` 会过滤所有 `null`；没有剩余模型时返回 `empty`，不进入地图渲染。

### 最新请求优先

入口为 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#requestVersion`。

- 每次显隐调用获得单调递增的本地版本号。
- 显示链路在查询后、地图命令后和异常处理中检查版本；过期调用返回 `superseded`。
- 隐藏链路在清除成功后检查版本；过期调用返回 `superseded`。
- 当前显示链路在地图命令前已经发送 `visible`。因此请求在等待 `replaceZones()` 时被更新调用淘汰，仍可能留下来自过期请求的 `visible` 事件，尽管其公开结果是 `superseded`。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 传给地图画布的初始缩放级别 |

### Emits

| 名称 | 载荷 | 当前发送语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 隐藏成功发送 `hidden`；明确请求错误、清除错误、地图返回 `empty` 或显示链路抛错时发送 `error`；非空围栏进入地图命令前即发送 `visible`，地图返回 `render-error` 时不再纠正 |

### Slots

| 名称 | Slot props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的工具区域 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 为以下结果之一：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 直接公共依赖

### `@shared/ui/map-canvas`

本模块只依赖下列最小公开面：

- `MapZoneModel`：`{ id: string; coordinates: Array<[number, number]> }`，由 `normalizeZone()` 产出。
- `MapCanvasExpose.replaceZones(zones)`：接收规范化围栏，返回 `success`、`empty` 或 `render-error` 结构化结果。
- `MapCanvasExpose.clearZones()`：清除围栏，返回 `Promise<void>`。
- `MapCanvas` 组件：接收本模块传入的 `initialZoom`，并通过模板引用提供上述 Expose 方法。

共享画布如何绘制、如何判定渲染错误不属于 HarborMap 边界；HarborMap 只拥有调用顺序、结果映射和状态事件。

## 数据转换与责任分层

显示链路包含三层语义转换：

1. `fetchHarborZones()` 返回 `{ code, data: HarborZoneDto[] }`。
2. `normalizeZone()` 将可用 DTO 转换为 `MapZoneModel`，无效或点数不足的数据变为 `null` 并被过滤。
3. `MapCanvasExpose.replaceZones()` 将模型集合转换为地图命令结果；HarborMap 再将该结果映射为 `HarborZoneResult` 和 `zoneStatusChange` 事件。

返回值与事件是两个独立公开信号。当前变化后的实现中，它们在地图 `render-error` 上会分叉：Promise 返回 `render-error`，事件流却只出现先发出的 `visible`。

## 问题排查与症状索引

### 症状：围栏渲染失败，但 UI 状态仍显示已开启

| 导航项 | 稳定入口或信号 |
| --- | --- |
| 第一检查点 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` 中 `emit('zoneStatusChange', 'visible')`、`replaceZones(zones)` 与非成功结果分支的相对顺序 |
| 复现前提 | 查询返回至少一个可规范化围栏，且 `replaceZones()` 以结构化结果 `{ status: 'render-error' }` 完成，而不是抛出异常 |
| 稳定返回信号 | Expose 方法解析为 `{ status: 'render-error' }` |
| 稳定事件信号 | `zoneStatusChange` 已出现 `visible`，且该 `render-error` 分支没有后续 `error` |
| 排除查询/转换故障 | 已调用 `replaceZones()` 说明查询、版本检查、规范化和非空过滤均已越过 |
| 下一验证入口 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`，复用 `fetchHarborZones` 与 `replaceZones` mock，观察 Expose 返回值及 `zoneStatusChange` 顺序 |

第一检查点用于定位状态分叉，不单独证明共享画布内部为何渲染失败。若 `replaceZones()` 抛出异常，当前稳定信号改为 `error` 事件加 `request-error` 返回值；这属于另一条错误映射路径。

## 状态与错误责任矩阵

| 场景 | 地图命令 | 公开返回 | 当前事件序列 | HarborMap 责任边界 |
| --- | --- | --- | --- | --- |
| 隐藏成功 | `clearZones()` 完成 | `success, count: 0` | `hidden` | 清除编排与成功事件 |
| 隐藏抛错 | `clearZones()` 抛错 | `render-error` | `error` | 清除异常映射 |
| 请求非 200 | 不调用地图 | `request-error` | `error` | 请求结果映射 |
| 规范化后为空 | 不调用地图 | `empty` | 无 | 数据过滤与空结果映射 |
| 地图替换成功 | `replaceZones()` 返回 `success` | `success, count` | `visible` | 地图调用、结果转发；`visible` 在调用前发送 |
| 地图返回空 | `replaceZones()` 返回 `empty` | `empty` | `visible` → `error` | 地图结果映射 |
| 地图返回渲染错误 | `replaceZones()` 返回 `render-error` | `render-error` | `visible` | 返回值与事件状态发生分叉 |
| 显示链路抛错 | 查询或替换抛错 | `request-error` | 已进入替换时为 `visible` → `error`，否则为 `error` | 异常统一映射 |
| 调用被更新版本淘汰 | 已越过的异步阶段完成 | `superseded` | 取决于淘汰前是否已发送 `visible` | 并发结果淘汰，不撤销已发事件 |

## 跨功能风险

- `zoneStatusChange` 与 `HarborZoneResult` 同时表达状态，但并非由单一最终状态提交点产生；事件提前发送会使两种公开信号不一致。
- `visible` 既用于成功语义，又在地图命令完成前表示尝试开始；任何以该事件作为最终可见状态的消费者都可能观察到超前状态。
- 显示链路的同一 `catch` 同时覆盖查询异常和地图替换异常，并统一返回 `request-error`；排障时必须先区分结构化 `render-error` 与抛出的异常。
- `requestVersion` 阻止过期 Promise 结果生效，但不会撤销已发送的事件；事件顺序也是并发验证的一部分。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| adapter | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` | 单元级输入输出检查 | enabled、ID、坐标解析和最少点数规则 | 真实地图能否绘制几何 | MapZoneModel 契约变化时联动共享 UI 检查 |
| 组件显隐与并发 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | Vue 组件测试 | 隐藏不请求、最新显示请求优先、Props/Emits/Slots/Expose 的预期覆盖 | 真实网络和真实地图渲染 | service、共享 MapCanvas 或事件时序变化时增加对应 mock 场景 |
| 渲染失败状态分叉 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | Vue 组件测试 | 通过有效 DTO 与 `replaceZones: render-error` 可稳定观察返回值和事件顺序 | MapCanvas 内部产生 render-error 的原因 | 修改共享地图命令契约时增加跨 owner 集成验证 |
| 直接公共依赖 | `packages/shared-ui/src/map-canvas/public.ts` | 类型契约检查 | HarborMap 使用的模型、Expose 方法和结构化结果仍可用 | 共享画布实现行为 | 公开类型或方法签名变化时联动 harbor-system 类型检查 |

模块测试当前可检索的覆盖包括隐藏路径、最新显示请求优先和四类 Vue 公开契约入口；文件中没有针对 `replaceZones()` 返回 `empty` 或 `render-error` 的现成用例。测试文件只表明预期和覆盖入口，不代表本次执行结果。

## 文档维护信息

- 文档 owner：`apps/harbor-system`
- 模块入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- 模块类型与深度：Vue component，detailed
- 边界结论：专属 service、adapter、types 和模块测试随组件共同演进；共享 MapCanvas 仅记录最小公开依赖；调用方排除
- 核心功能域：电子围栏显隐编排、围栏数据规范化、最新请求优先

