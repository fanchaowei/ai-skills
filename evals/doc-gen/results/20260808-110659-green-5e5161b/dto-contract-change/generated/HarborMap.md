---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 负责电子围栏的请求编排、后端 DTO 归一化、地图画布更新以及稳定的组件级显隐结果契约。

feature_index:
  - entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  - entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones
    body_section: 后端响应契约吸收
  - entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏 DTO 归一化

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  data_flow: 数据转换与责任分层
  risks: 跨功能风险

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 电子围栏地图组件

## 模块概述

HarborMap 将后端围栏响应转换为共享地图画布接受的 `MapZoneModel`，负责显隐命令、并发请求淘汰、错误结果映射，并通过 Props、Emits、Slots 和 Expose 提供稳定的组件契约。后端 DTO 字段与响应包裹层的变化在模块内部被吸收，不改变组件调用方使用的 `setZonesVisible()` 和 `HarborZoneResult`。

## 模块边界

| 角色 | 路径 | 边界事实 |
| --- | --- | --- |
| owned | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 组件入口，编排请求、并发版本、地图更新和组件公开契约。 |
| owned | `apps/harbor-system/src/components/harbor-map/types.ts` | 定义后端 DTO、显隐结果与 Expose 类型。 |
| owned | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | 定义围栏响应包裹结构并提供请求入口。 |
| owned | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | 将后端 DTO 转换为地图画布模型。 |
| owned | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 模块内组件验证入口，只证明测试表达的预期和覆盖范围。 |
| direct-public-dependency | `packages/shared-ui/src/map-canvas/public.ts` | 提供本模块实际使用的地图模型与画布命令契约。 |
| caller | `apps/harbor-system/src/pages/HarborPage.vue` | 通过 Expose 调用 HarborMap；其 checkbox 状态和失败回退不属于本模块事实。 |

模块以 `apps/harbor-system/src/components/harbor-map/HarborMap.vue` 为主入口。调用方实现无条件排除；共享地图画布仅记录 HarborMap 真实使用的最小公开契约。

## 功能目录

### 电子围栏显隐编排

入口为 `HarborMap.vue#setZonesVisible`。

- 每次显隐调用递增 `requestVersion`；旧请求在请求返回或画布更新后发现版本落后时返回 `{ status: 'superseded' }`，不提交旧结果。
- 隐藏路径不请求后端，直接调用 `MapCanvasExpose.clearZones()`；成功时发出 `zoneStatusChange: 'hidden'` 并返回 `{ status: 'success', count: 0 }`。
- 显示路径调用 `fetchHarborZones()`，只接受 `code === 200` 的响应，再读取 `response.data.items` 并交给 `normalizeZone()`。
- 没有可用围栏时返回 `{ status: 'empty' }`；地图画布成功替换后发出 `zoneStatusChange: 'visible'` 并返回成功数量。
- 请求异常或非 200 响应映射为 `request-error`；清除或替换画布失败映射为 `render-error`，并发出 `zoneStatusChange: 'error'`。

最小事实链：`setZonesVisible()` → `requestVersion` 编排 → `response.data.items` → `normalizeZone()` → `MapCanvasExpose.replaceZones()`/`clearZones()` → `HarborMap.spec.ts`。

### 后端响应契约吸收

入口为 `services/harbor-api.ts#fetchHarborZones`。

- `HarborApiResponse` 的当前结构为 `{ code: number; data: { items: HarborZoneDto[] } }`。
- `services/harbor-api.ts` 拥有响应包裹层的类型边界；组件编排在 `HarborMap.vue#setZonesVisible` 读取 `data.items`，不把该包裹结构暴露到 Vue 公开契约。
- 因此后端从 `data: HarborZoneDto[]` 变为 `data: { items: HarborZoneDto[] }` 时，模块内吸收位置是 service 的响应类型与组件的列表解包点。

### 围栏 DTO 归一化

入口为 `adapters/normalize-zone.ts#normalizeZone`。

- `HarborZoneDto` 的当前原始字段为 `zone_id`、`enabled` 和 `boundary`；`boundary` 使用下划线分隔点、逗号分隔坐标值。
- `normalizeZone()` 读取 `dto.boundary`，只接收 `enabled === '0'` 且 `zone_id` 非空的 DTO，过滤非有限数值坐标；少于三个有效点时返回 `null`。
- 成功转换结果为 `{ id: dto.zone_id, coordinates }`，把后端命名、字符串编码和无效记录过滤限制在 adapter 内。
- 因此后端字段从 `points` 改为 `boundary` 时，模块内吸收位置是 `types.ts#HarborZoneDto` 与 `normalize-zone.ts#normalizeZone`；地图画布模型和组件公开结果保持不变。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 透传给地图画布的初始缩放级别。 |

### Emits

| 事件 | 参数 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏成功显示、成功隐藏或请求/渲染错误时发出。`empty` 与 `superseded` 不产生该事件。 |

### Slots

| 名称 | 语义 |
| --- | --- |
| `toolbar` | 渲染在地图画布之前的工具栏内容。 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

### 模块内后端契约

```ts
interface HarborZoneDto {
  zone_id: string
  enabled: '0' | '1'
  boundary: string
}

interface HarborApiResponse {
  code: number
  data: { items: HarborZoneDto[] }
}
```

这两项是 service/adapter 的输入契约，不是 HarborMap 的 Vue 调用方契约。后端字段或包裹层再次变化时，应继续在 `HarborApiResponse`、`HarborZoneDto`、列表解包点和 `normalizeZone()` 之间完成吸收。

## 直接公共依赖

`packages/shared-ui/src/map-canvas/public.ts` 提供 HarborMap 实际使用的最小契约：

- `MapZoneModel`：`id: string` 与 `coordinates: Array<[number, number]>`。
- `MapCanvasExpose.replaceZones(zones)`：接收归一化围栏，返回 `success`、`empty` 或 `render-error`。
- `MapCanvasExpose.clearZones()`：清除围栏并返回 `Promise<void>`。

HarborMap 不拥有共享地图画布的内部渲染实现；adapter 负责在依赖边界前形成 `MapZoneModel`。

## 数据转换与责任分层

| 层级 | 输入 | 吸收责任 | 输出 |
| --- | --- | --- | --- |
| service | 后端响应 | 固定 `code` 与 `data.items` 包裹契约 | `HarborApiResponse` |
| component orchestration | `HarborApiResponse` | 检查响应码、从 `data.items` 解包 DTO 列表、处理并发与错误结果 | `HarborZoneDto[]` 或 `HarborZoneResult` |
| adapter | 单个 `HarborZoneDto` | 读取 `boundary`、解析坐标、过滤禁用或无效记录 | `MapZoneModel \| null` |
| shared map boundary | `MapZoneModel[]` | 执行替换或清除命令 | `MapZoneCommandResult`/`void` |

`data.items` 的包裹变化不应下沉到 adapter；`boundary` 的编码规则不应扩散到组件编排或共享地图画布。

## 跨功能风险

- `HarborZoneDto`、`HarborApiResponse`、组件列表解包点和测试夹具必须表达同一套后端契约；任一处仍使用 `points` 或数组型 `data` 都会使类型检查或围栏显示验证失真。
- `enabled === '0'` 是 adapter 当前接受围栏的条件。该值语义若改变，会同时影响空结果判断和地图渲染数量。
- `requestVersion` 同时约束请求响应和画布命令结果；绕过版本检查会允许旧请求覆盖较新的显隐意图。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件显隐与公开契约 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | 隐藏不请求后端、最新显示请求获胜、Props/Emits/Slots/Expose 的预期 | 真实后端响应、共享地图画布内部渲染、本次执行结果 | 并发策略、结果映射或 Vue 公开契约变化 |
| DTO 与响应契约 | `apps/harbor-system/src/components/harbor-map/types.ts`、`apps/harbor-system/src/components/harbor-map/services/harbor-api.ts`、`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | 类型与单元边界 | `boundary` 字段、`data.items` 包裹层和归一化输入能否保持一致 | 后端线上实际载荷是否符合声明 | 后端字段、包裹层或坐标编码规则变化 |
| 跨 owner 地图契约 | `packages/shared-ui/src/map-canvas/public.ts` | 类型/集成边界 | `MapZoneModel` 与画布命令签名是否仍能被 HarborMap 使用 | provider 内部绘制正确性 | 共享地图模型或命令结果联合类型变化 |

当前 `HarborMap.spec.ts` 的可见请求夹具仍使用数组型 `data` 和 `points` 字段，与 `dto-change.diff` 表达的 `data.items` 和 `boundary` 契约冲突。因此该测试文件仍是稳定验证入口，但其中相关夹具不能证明变更后的 DTO 与响应契约。

## 模块内事实冲突

| 来源 | 冲突内容 | 当前处理 |
| --- | --- | --- |
| `changes/dto-change.diff` 与生产模块变更 | 定义 `HarborZoneDto.boundary`、`HarborApiResponse.data.items`，并在 adapter/组件中读取新结构。 | 文档以该变化集描述模块更新后的后端契约及吸收位置。 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 最新请求用例仍构造 `data: HarborZoneDto[]`，且 DTO 使用 `points`。 | 保留为冲突证据，不将旧夹具写成当前实现契约，也不宣称其已验证新契约。 |

## 文档维护信息

- Owner：`apps/harbor-system`
- 模块类型：详细 Vue 组件（组件、service、adapter、类型与模块内测试共同构成边界）
- 主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`
- 后端契约吸收入口：`services/harbor-api.ts#HarborApiResponse`、`types.ts#HarborZoneDto`、`HarborMap.vue#setZonesVisible`、`adapters/normalize-zone.ts#normalizeZone`
- 直接公共依赖入口：`packages/shared-ui/src/map-canvas/public.ts`

