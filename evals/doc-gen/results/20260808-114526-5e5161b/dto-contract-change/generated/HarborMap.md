---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 编排电子围栏显隐，将后端围栏响应归一化为共享地图模型，并通过组件公开契约返回稳定结果。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏 DTO 归一化

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

# HarborMap - 电子围栏地图组件

## 模块概述

HarborMap 负责电子围栏的查询、响应解包、DTO 归一化、地图覆盖物替换或清除，以及并发请求淘汰和组件级结果映射。后端 DTO 与响应包裹的变化在本模块内部消化，向共享地图组件输出的 `MapZoneModel` 和 HarborMap 的 Vue 公开契约保持不变。

## 模块边界

### Owned

| 路径 | 角色 |
| --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 组件入口；编排显隐、响应码判断、响应列表解包、并发淘汰、地图命令和公开结果。 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | 定义后端围栏 DTO、组件命令结果和 Expose 接口。 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | 定义并返回 HarborMap 专属后端响应包裹。 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | 将后端围栏 DTO 转为共享地图模型，并过滤不可渲染数据。 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 模块内部组件验证入口。 |

### Direct public dependency

- `packages/shared-ui/src/map-canvas/public.ts`：HarborMap 真实使用 `MapCanvasExpose`、`MapZoneModel` 及地图命令结果语义。

### Excluded

- `apps/harbor-system/src/pages/HarborPage.vue` 是 HarborMap 的调用方，不属于模块实现边界；其状态、回退和测试不写入本文档。

边界结论：owner 为 `apps/harbor-system`，现有文档已位于 owner 的 `claudedocs/modules` 位置，无需移动。

## 功能目录

### 电子围栏显隐编排

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 每次调用先递增 `requestVersion`；异步阶段结束后版本不再是最新时返回 `{ status: 'superseded' }`，不继续提交旧结果。
- `visible === false` 时不请求后端，调用 `MapCanvasExpose.clearZones()`；最新调用成功后发出 `zoneStatusChange: 'hidden'` 并返回 `{ status: 'success', count: 0 }`。
- `visible === true` 时调用 `fetchHarborZones()`，只接受 `code === 200` 的响应。
- 组件从 `response.data.items` 取得 `HarborZoneDto[]`，逐项调用 `normalizeZone()`，丢弃 `null`；没有可渲染围栏时返回 `{ status: 'empty' }`。
- 归一化结果交给 `MapCanvasExpose.replaceZones()`；地图成功结果映射为组件 `{ status: 'success', count }` 并发出 `zoneStatusChange: 'visible'`。
- 请求异常或非 200 响应映射为 `request-error`；地图访问或替换异常映射为 `render-error`。错误分支发出 `zoneStatusChange: 'error'`，被淘汰的调用不发出状态事件。
- 最小事实链：`setZonesVisible` → `fetchHarborZones` / `requestVersion` → `response.data.items` → `normalizeZone` → `replaceZones` / `clearZones` → `HarborZoneResult` 与 `zoneStatusChange` → `HarborMap.spec.ts`。

### 围栏 DTO 归一化

入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`

- 输入为 `HarborZoneDto`：`zone_id: string`、`enabled: '0' | '1'`、`boundary: string`。
- 仅 `enabled === '0'` 且 `zone_id.trim()` 非空的数据进入坐标解析。
- `boundary` 使用 `_` 分隔点、`,` 分隔数值；每个点必须恰有两个有限数值，最终至少三个有效点。
- 有效 DTO 转为 `{ id: zone_id, coordinates }`；无效 DTO 返回 `null`，由组件编排层过滤。
- 最小事实链：`normalizeZone` → `boundary` 字符串解析与有效性过滤 → `MapZoneModel | null` → `setZonesVisible` 的过滤和地图替换 → `HarborMap.spec.ts` 的可见请求路径。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 透传给地图组件作为初始缩放级别。 |

### Emits

| 名称 | 载荷 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' | 'hidden' | 'error'` | 围栏完成显示、完成隐藏或请求/渲染错误时发出；`empty` 与 `superseded` 不发出对应事件。 |

### Slots

| 名称 | Slot props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的工具栏内容。 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 直接公共依赖

Provider：`packages/shared-ui/src/map-canvas/public.ts`

| 公开 symbol | HarborMap 实际使用的最小契约 | 使用入口 |
| --- | --- | --- |
| `MapZoneModel` | `{ id: string; coordinates: Array<[number, number]> }` | `normalizeZone()` 的成功输出。 |
| `MapCanvasExpose.replaceZones` | 接收 `MapZoneModel[]`，返回 `success`、`empty` 或 `render-error` 结果。 | `setZonesVisible(true)`。 |
| `MapCanvasExpose.clearZones` | 返回 `Promise<void>`。 | `setZonesVisible(false)`。 |

后端 DTO 字段由 `normalizeZone()` 吸收，响应包裹由 `fetchHarborZones()` 的返回类型和 `setZonesVisible()` 的 `data.items` 解包吸收；共享地图公开契约不因本次后端契约变化而改变。

## 数据转换与责任分层

| 层级 | 输入 | 责任 | 输出 |
| --- | --- | --- | --- |
| `types.ts` | 后端线协议 | 声明 `HarborZoneDto.boundary` 和组件稳定结果类型。 | `HarborZoneDto`、`HarborZoneResult`、`HarborMapExpose`。 |
| `services/harbor-api.ts` | 后端响应 | 声明并返回 `{ code, data: { items } }` 包裹，不承担地图模型转换。 | `HarborApiResponse`。 |
| `HarborMap.vue#setZonesVisible` | `HarborApiResponse` | 校验 `code`、从 `data.items` 解包列表、编排并发和错误结果。 | DTO 列表或组件命令结果。 |
| `normalize-zone.ts#normalizeZone` | 单个 `HarborZoneDto` | 读取 `boundary`，解析并过滤坐标，将线协议转换为地图领域模型。 | `MapZoneModel | null`。 |
| `MapCanvasExpose` | `MapZoneModel[]` | 替换或清除地图围栏。 | 地图命令结果。 |

DTO 字段改名应止于 adapter，响应外层包裹应止于 service 类型与组件解包点；除非地图领域模型本身变化，否则不应把后端字段或响应包裹传播到 `packages/shared-ui`。

## 状态与错误责任矩阵

| 条件 | 组件结果 | 事件/地图效果 |
| --- | --- | --- |
| 地图引用不可用 | `render-error` | 不调用地图命令。 |
| 隐藏成功且仍为最新调用 | `success, count: 0` | 清除围栏并发出 `hidden`。 |
| 请求抛错或 `code !== 200` | `request-error` | 发出 `error`。 |
| DTO 全部被过滤 | `empty` | 不调用 `replaceZones`，不发出状态事件。 |
| 地图替换返回 `empty` | `empty` | 发出 `error`。 |
| 地图替换失败或抛错 | `render-error` | 发出 `error`。 |
| 任一受版本检查保护的旧调用完成 | `superseded` | 不提交旧结果，不发出状态事件。 |

## 跨功能风险

- `HarborApiResponse.data.items`、`HarborZoneDto.boundary`、组件解包点和 adapter 读取字段必须同时保持一致；任一层仍使用旧 `data: HarborZoneDto[]` 或 `points` 都会破坏可见围栏链路。
- `requestVersion` 的检查点位于请求完成、清除完成和地图替换完成之后；移动或删除检查点会允许旧调用覆盖新调用。
- adapter 的过滤结果决定组件是否返回 `empty`；调整启用值、分隔符或最少点数会同时改变地图输入与组件结果语义。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件契约与隐藏路径 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | `initialZoom`、`toolbar`、`setZonesVisible`、`zoneStatusChange` 的预期接口，以及隐藏时不请求并调用 `clearZones`。 | 真实地图实现、真实后端响应和本次执行结果。 | Vue 公开契约或共享地图 Expose 变化时增加对应组件/跨 owner 检查。 |
| 并发淘汰与可见路径 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 最新可见请求提交地图、旧请求返回 `superseded` 的预期。 | service 的真实传输行为；当前可见请求夹具仍使用旧响应与 DTO 形状，不能证明 `data.items` 和 `boundary` 契约。 | 响应包裹、DTO 字段、adapter 规则或地图命令结果变化时同步覆盖对应层级。 |
| DTO 与响应类型 | `apps/harbor-system/src/components/harbor-map/types.ts`、`apps/harbor-system/src/components/harbor-map/services/harbor-api.ts`、`apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 类型/静态核对 | 线协议字段、响应包裹与消费点能否在 TypeScript 层保持一致。 | 后端运行时一定返回该形状。 | 后端运行时契约变化时增加 service 集成或契约验证。 |

长期前提：组件验证需要 Vue Test Utils 与 Vitest 环境；真实后端和真实地图行为需要各自 owner 的集成验证。

## 模块内事实冲突

输入变化集把响应形状改为 `data: { items: HarborZoneDto[] }`，并把 DTO 坐标字段改为 `boundary`；但模块内部 `HarborMap.spec.ts` 的可见请求夹具仍构造 `data: HarborZoneDto[]` 且使用 `points`。因此该用例目前只能作为并发淘汰意图与旧形状覆盖范围的证据，不能作为新 DTO/响应契约的验证证据。本文档不把测试夹具中的旧字段写成当前实现契约。

## 文档维护信息

- 文档位置：`apps/harbor-system/claudedocs/modules/HarborMap.md`
- 模块 owner：`apps/harbor-system`
- 维护入口：Vue 公开契约、`HarborZoneDto`、`HarborApiResponse`、`normalizeZone`、`MapCanvasExpose` 或模块内部验证范围变化时复核本文档。
- 边界约束：调用方页面始终排除；共享地图只记录 HarborMap 真实使用的公开声明。
