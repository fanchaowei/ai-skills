---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: complex-module
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 负责港区电子围栏的请求、标准化、地图显隐编排，以及对外公开稳定的组件状态结果。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据标准化
  zone_loading:
    entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones
    body_section: 围栏数据加载

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

# HarborMap - 港区电子围栏组件模块

## 模块概述

HarborMap 是港区电子围栏的组件边界。它向外提供初始缩放配置、工具栏插槽、围栏状态事件和显隐命令；模块内部负责请求 DTO、过滤并转换有效围栏、调用共享地图画布，并把上游结果归一化为稳定的 `HarborZoneResult`。

## 模块边界

| 路径 | 角色 | 当前职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 组件公开契约、请求版本控制、显隐编排、事件和结果映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 港区 DTO、公开命令结果和 Expose 类型 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 围栏数据请求入口及响应类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | `HarborZoneDto` 到 `MapZoneModel` 的标准化 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | HarborMap 实际使用的地图模型、命令结果和 Expose 声明 |

调用 HarborMap 的页面属于 `caller`，不进入模块事实边界。共享地图画布只记录 HarborMap 真实引用的公开声明，不扩展到 provider 内部实现。

## 功能目录

### 电子围栏显隐编排

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 每次调用递增 `requestVersion`；异步阶段返回后若版本落后，返回 `{ status: 'superseded' }`，不再发布该次调用的可见、隐藏或错误状态。
- `visible: false` 时调用 `MapCanvasExpose.clearZones()`；完成后发布 `hidden` 并返回 `{ status: 'success', count: 0 }`，异常映射为 `render-error` 并发布 `error`。
- `visible: true` 时依次请求、标准化、过滤并调用 `replaceZones()`；成功发布 `visible`，并透传成功渲染数量。
- 地图 provider 返回 `empty` 时发布 `error`，但方法结果保留为 `{ status: 'empty' }`。
- 地图 provider 返回 `render-error` 或 `partial` 时发布 `error`，并统一返回 `{ status: 'render-error' }`；`partial` 的 `count` 与 `skipped` 不穿透 HarborMap 公开契约。
- 地图实例尚未就绪时直接返回 `render-error`，不发布事件。

### 围栏数据标准化

入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`

- 只接收 `enabled === '0'` 且 `zone_id` 非空的 DTO。
- `points` 使用下划线分隔点、逗号分隔坐标，并过滤非有限数值坐标。
- 少于 3 个有效坐标时返回 `null`；有效数据转换为 `{ id, coordinates }`。
- HarborMap 会过滤所有 `null`；过滤后没有围栏时返回 `{ status: 'empty' }`，不调用地图 provider。

### 围栏数据加载

入口：`apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones`

- 请求入口返回 `Promise<HarborApiResponse>`，响应包含数值 `code` 和 `HarborZoneDto[]`。
- HarborMap 只把 `code === 200` 视为可继续处理的数据响应；其他 code 发布 `error` 并返回 `request-error`。
- 请求或显示链路抛出的异常在当前调用仍有效时发布 `error` 并返回 `request-error`；隐藏链路的清理异常单独映射为 `render-error`。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `initialZoom` | `number`（可选） | `12` | 作为 `initial-zoom` 传给共享地图画布 |

### Emits

| 事件 | 参数 | 说明 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏成功显示、成功隐藏或进入错误分支时发布；`empty`、`superseded` 和地图未就绪并不保证发布事件 |

### Slots

| 名称 | 参数 | 说明 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的命名工具栏插槽 |

### Expose

| 方法 | 签名 | 说明 |
| --- | --- | --- |
| `setZonesVisible` | `(visible: boolean) => Promise<HarborZoneResult>` | 显示或隐藏电子围栏，并返回本次调用的稳定结果 |

`HarborZoneResult`：

| status | 附加字段 | 模块语义 |
| --- | --- | --- |
| `success` | `count: number` | 操作完成；显示时为 provider 成功数量，隐藏时固定为 `0` |
| `empty` | 无 | 本地没有有效围栏，或 provider 返回 `empty` |
| `request-error` | 无 | 响应 code 非 200，或显示链路抛出异常 |
| `render-error` | 无 | 地图未就绪、清理失败，或 provider 返回 `render-error` / `partial` |
| `superseded` | 无 | 该异步调用已被更新调用淘汰 |

provider 新增的 `{ status: 'partial'; count: number; skipped: number }` 不新增 HarborMap 的公开结果分支，也不改变 Props、Emits、Slots 或 Expose 签名。

## 直接公共依赖

### `@shared/ui/map-canvas/public`

HarborMap 实际使用的最小公开契约：

```ts
interface MapZoneModel {
  id: string
  coordinates: Array<[number, number]>
}

type MapZoneCommandResult =
  | { status: 'success'; count: number }
  | { status: 'empty' }
  | { status: 'partial'; count: number; skipped: number }
  | { status: 'render-error' }

interface MapCanvasExpose {
  replaceZones(zones: MapZoneModel[]): Promise<MapZoneCommandResult>
  clearZones(): Promise<void>
}
```

HarborMap 依赖 `replaceZones()` 的结果区分成功、空数据和非成功渲染结果；对于新增的 `partial`，模块吸收上游细节并维持既有 `HarborZoneResult` 联合类型。

## 数据转换与责任分层

```text
fetchHarborZones()
  → HarborApiResponse.data: HarborZoneDto[]
  → normalizeZone(): MapZoneModel | null
  → 过滤 null 得到 MapZoneModel[]
  → MapCanvasExpose.replaceZones()
  → MapZoneCommandResult
  → HarborZoneResult + zoneStatusChange
```

- service 负责提供 DTO 响应边界。
- adapter 负责字段校验、坐标解析和地图模型转换。
- HarborMap 负责空集合短路、并发淘汰、provider 结果吸收和公开事件发布。
- MapCanvas provider 负责地图区域替换与清理；其内部渲染过程不属于 HarborMap 模块事实。

## 状态与错误责任矩阵

| 场景 | 方法结果 | `zoneStatusChange` |
| --- | --- | --- |
| 显示成功 | `success(count)` | `visible` |
| 隐藏成功 | `success(0)` | `hidden` |
| 本地标准化后为空 | `empty` | 不发布 |
| provider 返回 `empty` | `empty` | `error` |
| provider 返回 `partial` | `render-error` | `error` |
| provider 返回 `render-error` | `render-error` | `error` |
| 响应 code 非 200 | `request-error` | `error` |
| 显示链路抛出异常 | `request-error` | `error`，但已被淘汰时不发布 |
| 隐藏清理抛出异常 | `render-error` | `error` |
| 调用被更新调用淘汰 | `superseded` | 不发布 |
| 地图实例未就绪 | `render-error` | 不发布 |

## 跨功能风险

- `partial` 被有意折叠为 `render-error`，上游提供的成功数量与跳过数量不会对外暴露；若外部需要区分部分成功，必须同步扩展 `HarborZoneResult`、Expose 返回语义和事件设计。
- `empty` 的事件语义取决于产生阶段：本地过滤为空时不发布事件，provider 返回 `empty` 时发布 `error`。使用方不能只根据方法结果推断是否收到错误事件。
- 显示链路中的抛出异常统一映射为 `request-error`，其中也可能包含 `replaceZones()` 抛出的异常；调整异常分类时需要同时核对 service 与 provider 边界。
- `requestVersion` 是所有异步结果的有效性门禁；新增 await 点时应在发布事件或返回稳定结果前保持淘汰检查。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| 组件契约与交互 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 该测试文件中显式声明的 HarborMap 行为预期与覆盖边界 | 共享地图画布内部渲染和真实后端响应 | Props、Emits、Slots、Expose 或并发状态语义变化 | 测试环境能够挂载 Vue 组件并替换模块直接依赖 |
| 跨 owner 契约 | owner 的 TypeScript 类型检查（具体命令在当前输入中未显式声明） | 类型 | HarborMap 对 `MapCanvasExpose`、`MapZoneCommandResult` 和本地公开类型的静态兼容关系 | provider 运行时是否产生各结果分支 | `packages/shared-ui` 公开联合类型或方法签名变化 | 应用与共享包使用同一组可解析类型声明 |
| adapter | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` 的单元检查入口 | 单元 | DTO 过滤、坐标解析和最少点数规则的预期 | API code、地图渲染和组件事件 | DTO 字段、分隔格式或 `MapZoneModel` 变化 | 检查输入覆盖有效、禁用、空 id、非法坐标和点数不足数据 |

未读取测试断言，因此现有测试文件的具体覆盖项不能从当前证据进一步细化；这不改变生产代码与公开声明形成的当前契约事实。

## 文档维护信息

- 组件公开契约以 `HarborMap.vue` 的 `defineProps`、`defineEmits`、slot 和 `defineExpose` 为准。
- 结果联合类型以 `types.ts` 为准；provider 最小契约以 `packages/shared-ui/src/map-canvas/public.ts` 为准。
- 当 provider 结果联合、`setZonesVisible()` 的映射语义、DTO 转换规则或请求版本门禁变化时，应同步更新对应功能域、依赖契约、状态矩阵和验证范围。

