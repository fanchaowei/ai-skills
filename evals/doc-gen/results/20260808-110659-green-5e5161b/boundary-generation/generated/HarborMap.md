---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 组合共享地图画布，并通过公开方法编排港区电子围栏的查询、归一化、显隐、并发淘汰与状态通知。"

feature_index:
  map_container:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue
    body_section: 地图容器与工具栏
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_query:
    entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones
    body_section: 电子围栏查询入口
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据归一化

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

# HarborMap - 港区地图组件

## 模块概述

`HarborMap` 是港区地图的组件边界。它渲染共享 `MapCanvas`，向外提供地图初始缩放、工具栏插槽、围栏状态事件和 `setZonesVisible()` 方法；电子围栏开启时由模块内部完成数据取得、DTO 归一化、地图替换和过期请求淘汰，关闭时直接清除地图围栏。

## 模块边界

| 角色 | 路径 | 边界依据 |
| --- | --- | --- |
| owned | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 组件主入口，拥有公开 Vue 契约、围栏显隐编排与请求版本状态。 |
| owned | `apps/harbor-system/src/components/harbor-map/types.ts` | 只定义该组件使用和暴露的围栏 DTO、命令结果及 Expose 接口。 |
| owned | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | 被组件直接调用的专属港区围栏查询入口。 |
| owned | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | 将该模块的 `HarborZoneDto` 转为地图公开模型。 |
| owned | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 模块内部组件测试，记录稳定预期与覆盖范围。 |
| direct-public-dependency | `packages/shared-ui/src/map-canvas/public.ts` | 模块真实引用 `MapCanvasExpose` 和 `MapZoneModel`；只纳入实际使用的公开声明。 |

边界结论明确：目标目录内文件围绕同一组件及其专属围栏能力共同演进；共享地图声明保持为外部公开依赖，模块事实不向调用方向扩展。

## 功能目录

### 地图容器与工具栏

- 真实入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`。
- 组件渲染 `MapCanvas`，用 `mapCanvasRef` 保存其公开 Expose 引用，并把 `initialZoom` 绑定到地图画布的 `initial-zoom` 属性。
- 命名插槽 `toolbar` 位于地图画布之前，模块不处理插槽内容。
- 地图实例尚未可用时，`setZonesVisible()` 直接返回 `{ status: 'render-error' }`。
- 验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 中的公开契约用例覆盖 prop、slot 和 Expose 的可用性。

### 电子围栏显隐编排

- 真实入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。
- 每次调用先递增模块内 `requestVersion`；异步阶段结束后版本不再是最新的调用返回 `{ status: 'superseded' }`，并避免旧的显示请求继续替换地图或发送成功状态。
- `visible: false` 不查询围栏，调用 `MapCanvasExpose.clearZones()`；清除成功后发送 `zoneStatusChange: 'hidden'`，并返回 `{ status: 'success', count: 0 }`。
- `visible: true` 依次调用 `fetchHarborZones()`、检查响应码、用 `normalizeZone()` 转换并过滤无效数据、调用 `MapCanvasExpose.replaceZones()`，成功后发送 `zoneStatusChange: 'visible'` 并返回地图报告的数量。
- 非 200 响应和未被淘汰的外层异常发送 `zoneStatusChange: 'error'`；非 200 响应返回 `request-error`，外层异常也映射为 `request-error`。清除异常返回 `render-error`。地图替换返回非成功结果时，模块发送 `error`，并映射为 `empty` 或 `render-error`。
- 归一化后没有可用围栏时返回 `{ status: 'empty' }`，该分支不发送 `zoneStatusChange`。
- 验证入口：组件测试覆盖隐藏时不发起查询，以及两个并发显示请求只保留最新结果的预期。

### 电子围栏查询入口

- 真实入口：`apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones`。
- 返回契约为 `Promise<HarborApiResponse>`，其中 `code` 是数值状态码，`data` 是 `HarborZoneDto[]`。
- 当前实现返回 `{ code: 200, data: [] }`，没有网络请求或外部客户端依赖；因此未替换该实现时，显示流程会进入空围栏结果。
- 组件测试通过 mock 此入口构造围栏响应，只证明组件对约定响应的处理预期，不证明真实请求集成。

### 围栏数据归一化

- 真实入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。
- 输入是 `HarborZoneDto`；仅 `enabled === '0'`、`zone_id` 去空白后非空且包含至少三个有效坐标点的数据可形成地图模型。
- `points` 按 `_` 分隔点、按 `,` 分隔坐标并转为数值；不是二元有限数值的点会被过滤。
- 有效输出为 `MapZoneModel`：`id` 使用 DTO 的 `zone_id`，`coordinates` 使用过滤后的坐标；不满足条件时返回 `null`。
- 显示编排对转换结果执行 `null` 过滤后再交给 `replaceZones()`。
- 当前组件测试只通过一个三点有效 DTO 间接覆盖成功转换路径；无效状态、空标识、非法坐标和少于三点的分支没有独立测试入口。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`（可选） | `12` | 作为地图画布的初始缩放值向下绑定。 |

### Emits

| 事件 | 参数 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `status: 'visible' \| 'hidden' \| 'error'` | 围栏成功显示、成功清除或进入已映射错误分支时发送；`empty`、`superseded` 和地图实例缺失分支不发送。 |

### Slots

| 名称 | Slot props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 在地图画布之前插入外部工具栏内容。 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 的公开结果：

| 状态 | 附加字段 | 当前语义 |
| --- | --- | --- |
| `success` | `count: number` | 地图替换成功，或隐藏时成功清除；隐藏结果数量为 `0`。 |
| `empty` | 无 | 归一化后无有效围栏，或地图替换返回 `empty`。 |
| `request-error` | 无 | 围栏响应码不是 200，或显示流程发生未被并发淘汰的异常。 |
| `render-error` | 无 | 地图实例不可用、清除抛错，或地图替换返回非 `success`/`empty` 结果。 |
| `superseded` | 无 | 当前调用在异步阶段结束时已不是最新调用。 |

## 直接公共依赖

| Provider | 使用的公开 symbol | HarborMap 实际使用范围 |
| --- | --- | --- |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapCanvasExpose.clearZones()` | 隐藏电子围栏时清除地图图层，返回 `Promise<void>`。 |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapCanvasExpose.replaceZones(zones)` | 用归一化后的 `MapZoneModel[]` 替换围栏，读取 `success`、`empty` 或 `render-error` 结果及成功数量。 |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapZoneModel` | 适配器只构造 `id: string` 和 `coordinates: Array<[number, number]>`。 |

`MapCanvas` 的内部渲染方式、状态和测试不属于本模块事实。

## 数据转换与责任分层

电子围栏显示链路为：

`setZonesVisible(true)` → `fetchHarborZones()` 返回 `HarborZoneDto[]` → `normalizeZone()` 过滤并转换为 `MapZoneModel[]` → `MapCanvasExpose.replaceZones()` → `HarborZoneResult` 与 `zoneStatusChange`。

- Service 层只提供港区 DTO 响应，不负责判断地图可渲染性。
- Adapter 层负责启用标记、标识和坐标结构的有效性，并吸收 DTO 到共享地图模型的格式差异。
- 组件层负责请求版本、步骤编排、结果映射和公开事件；不复制共享地图内部渲染逻辑。

## 验证入口与证明范围

稳定验证入口为 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。

| 改动层级 | 检查类型 | 当前入口能证明的预期范围 | 不能证明的范围 | 扩大验证条件 |
| --- | --- | --- | --- | --- |
| 组件公开契约 | 组件测试 | `initialZoom` 可传入、`toolbar` 可渲染、`setZonesVisible` 被 Expose、成功隐藏会发送 `hidden`。 | 所有错误状态和真实 `MapCanvas` 渲染结果。 | Props、Emits、Slots、Expose 任一签名或触发语义变化。 |
| 隐藏编排 | 组件测试 | 隐藏时不调用 `fetchHarborZones`，调用 `clearZones`，并预期返回成功数量 `0`。 | 地图实例缺失、`clearZones` 抛错和并发隐藏异常。 | 清除契约、错误映射或请求版本规则变化。 |
| 并发显示 | 组件测试 | 两个显示请求并发时，最新响应进入地图替换，旧请求预期返回 `superseded`。 | 三次以上交错、显示与隐藏交错、替换期间被淘汰。 | 修改 `requestVersion`、异步步骤或淘汰检查位置。 |
| DTO 归一化 | 组件测试中的间接路径 | 一个 `enabled: '0'` 且有三个有效坐标的 DTO 可进入替换流程。 | 各无效 DTO 分支、坐标边界和 adapter 独立行为。 | 修改 `HarborZoneDto`、`MapZoneModel` 或 `normalizeZone()` 规则时增加 adapter 单元测试。 |
| Service 与共享地图集成 | 无独立集成入口 | 现有测试通过 mock/stub 固定两端公开形状。 | 真实请求、真实地图渲染、跨 owner 兼容和运行环境。 | `fetchHarborZones()` 接入客户端，或 `MapCanvasExpose`/`MapZoneModel` 契约变化时增加集成与类型检查。 |

测试文件只记录预期与覆盖范围，不代表当前实现符合全部预期，也不代表本次已执行测试。

## 文档维护信息

- 事实范围：上述 owned 文件，以及模块真实引用的共享地图公开声明。
- 更新依据：生产代码、模块内部测试和直接公共依赖声明。
- 维护原则：调用方保持排除；公开契约、入口 symbol、结果状态、依赖声明或验证入口变化时同步更新本文档。
