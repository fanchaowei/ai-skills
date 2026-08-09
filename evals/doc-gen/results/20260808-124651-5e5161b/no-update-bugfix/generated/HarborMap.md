---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 负责港区电子围栏的查询、规范化、地图显隐编排与并发结果淘汰。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  latest_request_guard:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 最新请求结果保护

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

# HarborMap - 港区电子围栏组件

## 模块概述

HarborMap 通过公开方法控制港区电子围栏的显示与隐藏。显示链路负责取得围栏 DTO、转换为地图模型并提交给地图画布；隐藏链路清除地图围栏。每次调用都会推进请求版本，异步完成时只有最新调用可以提交状态结果。

## 模块边界

| 角色 | 路径 | 模块内职责 |
| --- | --- | --- |
| owned | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 组件公开契约、显隐编排、状态发出和请求版本控制 |
| owned | `apps/harbor-system/src/components/harbor-map/types.ts` | DTO、公开方法和结果联合类型 |
| owned | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | 围栏查询入口及其响应类型 |
| owned | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | 围栏 DTO 到地图模型的规范化 |
| owned | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件契约与并发行为的稳定验证入口 |
| direct-public-dependency | `packages/shared-ui/src/map-canvas/public.ts` | 地图围栏模型、渲染命令结果和画布公开方法 |

调用 HarborMap 的页面或其他组件属于 `caller`，不属于本模块边界。

## 功能目录

### 电子围栏显隐编排

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- `setZonesVisible(false)` 调用地图画布的 `clearZones()`；最新调用清除成功后发出 `zoneStatusChange: hidden`，并返回 `{ status: 'success', count: 0 }`。
- `setZonesVisible(true)` 调用 `fetchHarborZones()`。非 `200` 响应发出 `zoneStatusChange: error` 并返回 `request-error`。
- 有效 DTO 经 `normalizeZone()` 转换后交给 `replaceZones()`；没有有效围栏时返回 `empty`，不提交地图渲染。
- 地图替换成功时发出 `zoneStatusChange: visible` 并返回成功计数；地图空结果映射为 `empty`，其他非成功渲染结果映射为 `render-error`。
- 地图画布引用尚不可用时直接返回 `render-error`。

### 围栏数据规范化

入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`

- 仅接收 `enabled === '0'` 且 `zone_id` 去除空白后非空的 DTO。
- `points` 以 `_` 分隔坐标点，以 `,` 分隔数值；非二元或非有限数值坐标会被过滤。
- 少于三个有效坐标时返回 `null`；否则返回 `{ id, coordinates }` 形式的 `MapZoneModel`。

### 最新请求结果保护

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 每次调用先递增模块内 `requestVersion`，并保存本次 `currentVersion`。
- 在查询、清除或渲染等异步边界完成后，旧版本调用返回 `{ status: 'superseded' }`。
- 被淘汰的旧调用不发出 `visible`、`hidden` 或 `error` 状态，避免覆盖较新调用的结果。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 传递给地图画布的初始缩放级别 |

### Emits

| 事件 | 载荷 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 最新调用完成显示、隐藏或发生需要上报的请求/渲染错误 |

`empty`、`superseded` 以及地图引用尚不可用时的直接 `render-error` 不发出该事件。

### Slots

| 名称 | 语义 |
| --- | --- |
| `toolbar` | 渲染在地图画布之前的工具栏内容 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 的稳定状态为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 直接公共依赖

HarborMap 使用 `@shared/ui/map-canvas` 组件，并从 `packages/shared-ui/src/map-canvas/public.ts` 使用以下最小公开契约：

- `MapCanvasExpose.clearZones(): Promise<void>`：清除已渲染围栏。
- `MapCanvasExpose.replaceZones(zones)`：替换围栏并返回 `success`、`empty` 或 `render-error`。
- `MapZoneModel`：提供 `id` 与坐标数组，是 `normalizeZone()` 的输出和 `replaceZones()` 的输入。

## 数据转换与责任分层

| 阶段 | 入口 | 输入 | 输出或责任 |
| --- | --- | --- | --- |
| 查询 | `services/harbor-api.ts#fetchHarborZones` | 无 | `HarborApiResponse`，包含状态码与 `HarborZoneDto[]` |
| 规范化 | `adapters/normalize-zone.ts#normalizeZone` | `HarborZoneDto` | 有效 `MapZoneModel` 或 `null` |
| 编排 | `HarborMap.vue#setZonesVisible` | `visible: boolean` | 过滤无效模型、控制版本、映射请求与渲染结果 |
| 渲染 | `MapCanvasExpose` | `MapZoneModel[]` 或清除命令 | 地图命令结果，由 HarborMap 转换为 `HarborZoneResult` |

## 问题排查与症状索引

| 症状或结果 | 第一检查点 | 稳定信号 | 下一验证入口 |
| --- | --- | --- | --- |
| `request-error` | `fetchHarborZones()` 的响应码或异常 | 非 `200` 响应，或显示链路抛出异常 | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones` |
| `empty` | `normalizeZone()` 的过滤结果 | 没有有效模型，或地图画布返回 `empty` | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` |
| `render-error` | `mapCanvasRef` 与地图命令结果 | 画布引用不可用、清除异常或非成功渲染结果 | `packages/shared-ui/src/map-canvas/public.ts#MapCanvasExpose` |
| `superseded` | `requestVersion` 比较 | 当前调用版本不再是最新版本 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` |

第一检查点用于缩小范围，不代表根因结论。

## 跨功能风险

- 请求版本检查必须覆盖所有异步成功与异常出口；遗漏出口会让旧调用发出状态或返回非 `superseded` 结果。
- `normalizeZone()` 当前只接收 `enabled === '0'` 的 DTO；上游启用值语义变化会直接改变有效围栏集合。
- `fetchHarborZones()` 的响应数据由编排层直接执行 `.map()`；响应结构变化需要同步调整服务契约或编排层。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件公开契约 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | `initialZoom`、`toolbar`、公开方法以及隐藏成功事件的预期 | 真实地图组件的渲染效果 | Props、Emits、Slots 或 Expose 变化 |
| 显隐编排 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | 隐藏不请求围栏；可见请求只提交最新结果的预期 | 真实网络响应、隐藏异常分支和地图提供方内部行为 | 错误映射、并发出口或跨 owner 地图契约变化 |
| 类型与依赖契约 | `apps/harbor-system/src/components/harbor-map/types.ts`、`packages/shared-ui/src/map-canvas/public.ts` | 类型检查入口 | 结果联合类型与画布公开方法的静态兼容范围 | 运行时服务响应是否符合声明 | DTO、结果状态或 `MapCanvasExpose` 变化 |

## 文档维护信息

- 模块事实入口：`apps/harbor-system/src/components/harbor-map/`。
- 直接公共依赖声明：`packages/shared-ui/src/map-canvas/public.ts`。
- 更新触发：公开契约、返回状态语义、请求版本不变量、规范化规则、地图公开依赖、稳定诊断或验证入口发生变化。
- 调用方实现、提交历史和某次验证执行状态不写入本文档。
