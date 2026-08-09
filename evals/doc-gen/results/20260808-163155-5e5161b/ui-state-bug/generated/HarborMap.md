---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: "HarborMap"
module_type: "component"
owner: "apps/harbor-system"
audience: ai
read_mode: progressive
depth: "detailed"
summary: "HarborMap 查询、筛选并向地图画布提交港区电子围栏，同时公开显隐命令、状态事件和工具栏插槽。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  request_arbitration:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 可见请求竞态淘汰
  component_contract:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue
    body_section: 组件公开接口

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

`HarborMap` 将围栏查询、DTO 规范化、并发请求淘汰和地图画布命令编排在一个 Vue 组件内。组件通过公开方法返回结构化结果，并通过事件发布可见、隐藏或错误状态。

## 模块边界

模块拥有以下实现：

- `apps/harbor-system/src/components/harbor-map/HarborMap.vue`：组件入口、异步编排、状态事件和公开方法。
- `apps/harbor-system/src/components/harbor-map/types.ts`：围栏 DTO、公开结果联合类型和 Expose 接口。
- `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts`：专属 DTO 到地图模型的转换。
- `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts`：专属围栏查询入口及响应类型。
- `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`：模块内部组件验证入口。

`packages/shared-ui/src/map-canvas/public.ts` 是直接公共依赖，只提供本模块实际使用的地图模型与命令结果契约。调用方不属于本模块边界。

## 功能目录

### 电子围栏显隐编排

入口为 `HarborMap.vue#setZonesVisible`。

- `visible === false` 时不请求围栏，调用 `MapCanvasExpose.clearZones()`；最新请求完成后发布 `hidden`，返回 `{ status: 'success', count: 0 }`。
- `visible === true` 时调用 `fetchHarborZones()`；非 `200` 响应发布 `error` 并返回 `request-error`。
- 有效围栏为空时返回 `empty`，不向画布提交数据。
- 有有效围栏时，当前实现先发布 `visible`，再等待 `replaceZones()` 的结构化结果。
- `replaceZones()` 返回 `success` 时，公开方法返回其 `count`。
- `replaceZones()` 返回 `empty` 时，当前实现再发布 `error` 并返回 `empty`。
- `replaceZones()` 返回 `render-error` 时，当前实现返回 `render-error`，但不会在先前的 `visible` 之后发布终止错误事件。
- 组件实例引用不存在时直接返回 `render-error`，不发布状态事件。

### 围栏数据规范化

入口为 `normalize-zone.ts#normalizeZone`。

- 仅接受 `enabled === '0'` 且 `zone_id` 去除空白后非空的 DTO。
- `points` 使用下划线拆分点、逗号拆分坐标，并通过 `Number` 转为数值。
- 非二维、非有限数值坐标会被过滤；少于三个有效坐标时返回 `null`。
- 有效 DTO 转换为 `{ id, coordinates }`，随后由组件过滤 `null` 并提交给地图画布。

### 可见请求竞态淘汰

入口为 `HarborMap.vue#setZonesVisible` 中的 `requestVersion`。

- 每次显隐命令递增版本号。
- 可见请求在查询完成后和画布命令完成后分别比较当前版本；旧版本返回 `superseded`。
- 当前 `visible` 事件发生在画布命令完成前，因此一个随后被淘汰的请求仍可能已经发布 `visible`。
- 隐藏命令在清除完成后比较版本；旧版本不发布 `hidden`，返回 `superseded`。

### 组件公开接口

入口为 `HarborMap.vue` 的 Props、Emits、Slots 和 Expose 声明。

- `initialZoom` 具有默认值 `12`，并传给地图画布组件。
- 命名插槽 `toolbar` 位于地图画布之前。
- `setZonesVisible` 通过 `defineExpose` 提供给组件引用。
- `zoneStatusChange` 发布结构化状态字面量。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 传给地图画布的初始缩放值。 |

### Emits

| 名称 | 参数 | 当前发布位置 |
| --- | --- | --- |
| `zoneStatusChange` | `status: 'visible' \| 'hidden' \| 'error'` | 隐藏成功后发布 `hidden`；请求或部分错误分支发布 `error`；可见流程在画布提交完成前发布 `visible`。 |

### Slots

| 名称 | 参数 | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 在地图画布之前插入围栏工具栏内容。 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 为：

```ts
type HarborZoneResult =
  | { status: 'success'; count: number }
  | { status: 'empty' }
  | { status: 'request-error' }
  | { status: 'render-error' }
  | { status: 'superseded' }
```

## 直接公共依赖

### `@shared/ui/map-canvas/public`

本模块使用以下最小公开契约：

- `MapZoneModel`：`id` 与二维坐标数组，作为 `normalizeZone()` 的输出和 `replaceZones()` 的输入。
- `MapCanvasExpose.replaceZones(zones)`：返回 `success`、`empty` 或 `render-error`。
- `MapCanvasExpose.clearZones()`：返回 `Promise<void>`。

组件还渲染 `@shared/ui/map-canvas` 默认导出的地图组件，并将 `initialZoom` 与实例引用接入上述编排；本模块不拥有地图画布内部渲染实现。

## 数据转换与责任分层

可见流程的最短事实链为：

```text
setZonesVisible(true)
  → fetchHarborZones()
  → HarborZoneDto[]
  → normalizeZone()
  → MapZoneModel[]
  → zoneStatusChange('visible')
  → MapCanvasExpose.replaceZones()
  → HarborZoneResult
```

责任边界：

- service 提供 `code + data` 响应，不解释地图渲染结果。
- adapter 负责过滤禁用、无标识或坐标不足的 DTO，不发布 UI 状态。
- 地图画布依赖负责返回 `success`、`empty` 或 `render-error`。
- `HarborMap` 负责将请求、规范化、竞态和画布结果映射为公开返回值与事件；事件与返回值的一致性属于组件边界。

## 状态与错误责任矩阵

| 条件 | 事件 | 公开结果 | 责任边界 |
| --- | --- | --- | --- |
| 地图实例不存在 | 无 | `render-error` | 组件实例接入 |
| 隐藏且清除完成、版本最新 | `hidden` | `success, count: 0` | 组件编排 |
| 隐藏清除抛出异常 | `error` | `render-error` | 画布调用与组件映射 |
| 查询响应 code 非 200 | `error` | `request-error` | service 响应与组件映射 |
| 规范化后无有效围栏 | 无 | `empty` | adapter 输出与组件判空 |
| 画布返回 success、版本最新 | `visible` 在调用画布前发布 | `success, count` | 画布结果与组件映射 |
| 画布返回 empty、版本最新 | `visible` 后再发布 `error` | `empty` | 画布结果与组件映射 |
| 画布返回 render-error、版本最新 | 仅已发布的 `visible` | `render-error` | 画布结果与组件事件映射 |
| 可见流程在画布完成后被新版本淘汰 | 可能已发布 `visible` | `superseded` | 组件竞态与事件时序 |

## 问题排查与症状索引

### 围栏渲染失败，但可见状态信号仍存在

| 导航项 | 稳定入口或信号 |
| --- | --- |
| 第一检查点 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` 中 `emit('zoneStatusChange', 'visible')`、`await mapCanvas.replaceZones(zones)` 和 `result.status` 分支的先后关系。 |
| 稳定结构化信号 | 同一次公开方法调用中，画布返回 `{ status: 'render-error' }`，公开 Promise 返回 `{ status: 'render-error' }`，但事件序列已包含 `zoneStatusChange: 'visible'` 且没有后续 `error`。 |
| 故障边界 | 查询与规范化已产生非空 `MapZoneModel[]`；画布提交报告渲染失败；组件负责的事件映射在画布成功确认前发布可见状态。画布为何失败不由本模块事实解释。 |
| 下一验证入口 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 的组件级 `MapCanvasStub`；以 `replaceZones` 返回 `render-error` 的场景覆盖公开返回值与 `zoneStatusChange` 序列。 |

该结构化信号用于定位事件/结果分歧，不单独证明地图画布失败的根因。

## 跨功能风险

- `zoneStatusChange` 与 `HarborZoneResult` 是同一命令的两条公开结果通道；发布时间不同会形成状态分歧。
- `requestVersion` 只在异步阶段完成后淘汰旧结果；异步阶段之前发布的事件不会被撤回。
- `replaceZones()` 抛出异常会进入外层 catch 并映射为 `request-error`，而结构化返回 `render-error` 会映射为 `render-error`；异常形式会改变公开错误类别。
- 规范化结果为空时不发布状态事件，事件消费者不能仅凭事件区分“无有效围栏”和“尚未完成”。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| 组件契约与隐藏流程 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | Props、`toolbar` slot、Expose 存在，以及隐藏命令不请求数据、调用清除并发布 `hidden` 的预期。 | 真实地图画布清除效果、页面调用方状态。 | Props、Slots、Emits 或 Expose 变化时扩展契约断言。 | Vue Test Utils、Vitest 与可替换的地图组件 stub。 |
| 可见请求竞态 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 两个并发可见请求中旧请求返回 `superseded`、只有最新查询结果进入画布提交的预期。 | 画布提交期间发生竞态时的事件顺序、真实网络时序。 | 改动 `requestVersion` 检查点或事件发布时间时增加异步阶段覆盖。 | 可控制的 `fetchHarborZones` Promise 与 `replaceZones` mock。 |
| 渲染失败状态映射 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | `replaceZones` 的结构化失败结果与公开返回值、事件序列之间的预期关系。 | 地图画布内部渲染失败原因。 | `MapZoneCommandResult`、事件语义或错误映射变化时扩大到共享画布契约检查。 | `MapCanvasStub` 暴露与生产依赖同形的 `replaceZones`。 |
| DTO 规范化 | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` | 单元入口 | 启用标志、标识、坐标解析和最少点数规则可被独立覆盖。 | service 返回数据真实性与地图实际绘制。 | DTO 或 `MapZoneModel` 契约变化时增加 adapter 与共享类型联合检查。 | 输入 DTO 和共享地图模型声明保持可导入。 |

## 文档维护信息

- 当前 owner：`apps/harbor-system`。
- 模块公开契约以 `HarborMap.vue` 与 `types.ts` 为准。
- 地图依赖的最小契约以 `packages/shared-ui/src/map-canvas/public.ts` 为准。
- 诊断事实需要同时核对事件序列、公开 Promise 结果和 `MapZoneCommandResult`，不能只核对其中一条通道。
