---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: "HarborMap"
module_type: "component"
owner: "apps/harbor-system"
audience: ai
read_mode: progressive
depth: "detailed"
summary: "港口地图承载组件，负责地图工具栏插槽、初始缩放透传，以及电子围栏的查询、转换、显隐编排和结果通知。"

feature_index:
  map_host:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue
    body_section: 地图承载与工具栏
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 电子围栏数据转换

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港口地图组件

## 模块概述

HarborMap 是 `apps/harbor-system` 拥有的港口地图承载组件。它渲染共享 `MapCanvas`，向外提供工具栏插槽与初始缩放配置，并通过公开方法编排电子围栏的加载、规范化、渲染、清除、并发淘汰和结果通知。

## 模块边界

模块拥有以下文件：

| 路径 | 角色 | 边界依据 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 组件主入口，定义 Vue 公开契约并编排地图与电子围栏。 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 只承载 HarborMap 的 DTO、公开返回结果和 Expose 类型。 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 将 HarborMap 的围栏 DTO 转为地图公开模型。 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 提供 HarborMap 专用围栏查询入口及响应类型。 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块内部组件验证入口，只证明其中声明的预期与覆盖范围。 |

`packages/shared-ui/src/map-canvas/public.ts` 是直接公共依赖，只记录 HarborMap 实际使用的 `MapZoneModel`、`MapCanvasExpose.clearZones()` 和 `MapCanvasExpose.replaceZones()` 契约，不归 HarborMap 所有。

`apps/harbor-system/src/pages/HarborPage.vue` 的依赖方向是调用 HarborMap 公开契约，因此是 caller，明确排除在模块边界之外；本文档不记录其状态、回退、测试或其他实现事实。

## 功能目录

### 地图承载与工具栏

真实入口是 `apps/harbor-system/src/components/harbor-map/HarborMap.vue`。组件渲染共享 `MapCanvas`，把 `initialZoom` 作为 `initial-zoom` 传入，并在地图之前渲染命名 `toolbar` slot。`mapCanvasRef` 只用于调用共享地图暴露的围栏命令。

### 电子围栏显隐编排

真实入口是 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`，公开签名为：

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

- 每次调用先递增 `requestVersion`；异步清除、查询或替换完成后，如果版本已落后，则返回 `{ status: 'superseded' }`，旧调用不再发布成功状态。
- 地图实例尚不可用时直接返回 `{ status: 'render-error' }`。
- `visible === false` 时不查询围栏，调用 `clearZones()`；当前调用仍是最新版本时发出 `zoneStatusChange: 'hidden'`，并返回 `{ status: 'success', count: 0 }`。清除抛错时发出 `error` 并返回 `render-error`。
- `visible === true` 时调用 `fetchHarborZones()`；非 `200` 响应发出 `error` 并返回 `request-error`。该 service 当前实现直接返回 `{ code: 200, data: [] }`，没有外部请求，因此未替换 service 的运行路径会进入 `empty`。
- 查询数据经 `normalizeZone()` 映射并过滤 `null`；没有可渲染围栏时返回 `empty`，不调用 `replaceZones()`。
- 有可渲染围栏时调用 `replaceZones(zones)`；共享地图返回成功时发出 `visible` 并透传实际 `count`。共享地图返回 `empty` 时映射为 `empty`，其他非成功结果映射为 `render-error`，并发出 `error`。
- 显示分支中抛出的异常统一发出 `error` 并返回 `request-error`；如果异常处理时该调用已落后，则优先返回 `superseded`。

最小验证锚点是 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`：它声明隐藏时不发起查询且清除地图、并发显示请求只保留最新结果，以及公开入口可调用的预期。修改 DTO 过滤、错误映射或真实共享地图集成时，需要在此入口之外扩大对应 adapter、失败分支或集成验证范围。

### 电子围栏数据转换

真实入口是 `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。

- 仅 `enabled === '0'` 且 `zone_id.trim()` 非空的 DTO 继续转换。
- `points` 以 `_` 分隔点、以 `,` 分隔坐标，并通过 `Number` 转换；只保留恰好两个有限数值的坐标点。
- 少于三个有效点时返回 `null`；否则返回 `{ id: dto.zone_id, coordinates }`，满足 `MapZoneModel`。
- 转换失败通过 `null` 表达，由 `setZonesVisible()` 在调用 `replaceZones()` 前过滤。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 作为共享 `MapCanvas` 的初始缩放值。 |

### Emits

| 名称 | 载荷 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏成功显示、成功隐藏或显隐流程进入错误结果时发出；`empty` 与 `superseded` 不发出对应事件。 |

### Slots

| 名称 | Slot props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 在地图之前插入围栏或地图工具控件。 |

### Expose

| 名称 | 签名 | 返回语义 |
| --- | --- | --- |
| `setZonesVisible` | `(visible: boolean) => Promise<HarborZoneResult>` | 返回 `success`、`empty`、`request-error`、`render-error` 或 `superseded`；`success` 携带 `count`。 |

## 直接公共依赖

| Provider | 使用的公开契约 | HarborMap 内使用入口 |
| --- | --- | --- |
| `@shared/ui/map-canvas` | `MapCanvas` 组件 | `HarborMap.vue` 渲染地图并传入初始缩放。 |
| `packages/shared-ui/src/map-canvas/public.ts#MapCanvasExpose` | `clearZones(): Promise<void>`；`replaceZones(zones): Promise<MapZoneCommandResult>` | `HarborMap.vue#setZonesVisible` 清除或替换围栏。 |
| `packages/shared-ui/src/map-canvas/public.ts#MapZoneModel` | `{ id: string; coordinates: Array<[number, number]> }` | `normalize-zone.ts#normalizeZone` 的有效输出。 |

本文档不复制共享地图如何渲染、存储或清除围栏的内部实现。

## 数据转换与责任分层

| 层级 | 入口 | 输入 | 输出或责任 |
| --- | --- | --- | --- |
| 查询 | `harbor-api.ts#fetchHarborZones` | 无参数 | `HarborApiResponse`；当前实现固定返回 `code: 200` 与空 `data`。 |
| 规范化 | `normalize-zone.ts#normalizeZone` | `HarborZoneDto` | 有效 `MapZoneModel` 或 `null`。 |
| 编排 | `HarborMap.vue#setZonesVisible` | 显隐布尔值 | 过滤无效模型、处理并发版本、映射请求与渲染结果。 |
| 共享渲染 | `MapCanvasExpose` | `MapZoneModel[]` 或清除命令 | 返回最小渲染结果，HarborMap 再映射为 `HarborZoneResult`。 |

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件公开契约与基本交互 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | Vue 组件测试 | `initialZoom`、`toolbar`、Expose 可达性，以及成功隐藏时的事件预期。 | 真实共享地图渲染、真实请求响应和所有失败状态。 | 修改 Props、Emits、Slots、Expose 或 MapCanvas 接入时增加对应契约与集成覆盖。 |
| 围栏隐藏 | 同上 | 组件测试 | 隐藏不查询围栏、调用 `clearZones()` 并返回清零结果的预期。 | 清除抛错与地图实例缺失路径。 | 修改清除命令或错误映射时补充失败分支覆盖。 |
| 并发显示 | 同上 | 组件测试 | 较旧显示请求返回 `superseded`、只有最新结果进入替换的预期。 | 隐藏与显示交错、替换完成后的竞争窗口。 | 修改 `requestVersion` 或异步边界时增加交错时序覆盖。 |

现有稳定验证入口不覆盖无效 DTO 过滤、请求失败、地图失败、地图实例缺失或真实共享地图集成；这些边界发生变化时，最小验证范围需要随之扩大。模块内部测试文件只声明预期和覆盖范围，不代表某次执行结论。

## 文档维护信息

- 事实入口：HarborMap 生产代码、模块内部测试，以及 HarborMap 真实引用的共享地图公开声明。
- 更新触发：Vue 公开契约、`HarborZoneResult`、查询响应、DTO 转换规则、并发淘汰逻辑、MapCanvas 最小公开契约或稳定验证入口发生变化。
- 边界约束：调用方实现始终排除；共享地图只记录 HarborMap 实际使用的最小公开契约。
