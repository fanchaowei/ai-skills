---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 编排港区围栏显隐，将后端响应与 DTO 归一化为共享地图组件可渲染的围栏模型。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 围栏显隐编排
  response_contract_absorption:
    entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#HarborApiResponse
    body_section: 后端响应契约吸收
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏 DTO 归一化
  request_arbitration:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 并发请求淘汰

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

# HarborMap - 港区围栏地图组件

## 模块概述

HarborMap 提供港区围栏的显隐命令，负责请求后端围栏、吸收响应包裹与 DTO 字段契约、过滤并归一化坐标，再把 `MapZoneModel[]` 交给共享 `MapCanvas` 渲染。隐藏命令不请求后端，直接清除地图围栏。

## 模块边界

| 路径 | 角色 | 模块内职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 组件公开契约、显隐编排、响应解包、请求淘汰和结果映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 后端围栏 DTO、组件暴露接口和命令结果类型 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 港区围栏请求及后端响应包裹类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 将后端 DTO 转为共享地图围栏模型 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 组件显隐、并发淘汰和公开接口的稳定验证入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | HarborMap 实际使用的地图围栏模型与 expose 契约 |

`apps/harbor-system/src/pages/HarborPage.vue` 是 HarborMap 的调用方，不属于本模块边界；其状态、失败回退和测试不构成 HarborMap 模块事实。

## 功能目录

### 围栏显隐编排

入口为 `HarborMap.vue#setZonesVisible`。

- `visible === false`：调用 `MapCanvasExpose.clearZones()`；成功后发出 `zoneStatusChange('hidden')`，返回 `{ status: 'success', count: 0 }`。
- `visible === true`：调用 `fetchHarborZones()`，仅在 `response.code === 200` 时继续处理 `response.data.items`。
- 归一化后没有有效围栏时返回 `{ status: 'empty' }`，不调用 `replaceZones()`。
- 地图替换成功后发出 `zoneStatusChange('visible')`，并返回共享地图结果中的 `count`。
- 请求异常、非 200 响应或地图渲染失败分别归入 `request-error` 或 `render-error`，错误分支发出 `zoneStatusChange('error')`；被更新请求淘汰的分支返回 `superseded`。

### 后端响应契约吸收

后端响应变化由模块内以下位置吸收：

| 后端契约 | 模块内吸收位置 | 吸收后的下游边界 |
| --- | --- | --- |
| 响应数据由 `data: HarborZoneDto[]` 改为 `data: { items: HarborZoneDto[] }` | `services/harbor-api.ts#HarborApiResponse` 声明响应包裹；`HarborMap.vue#setZonesVisible` 从 `response.data.items` 取出 DTO 列表 | `normalizeZone()` 仍接收单个 `HarborZoneDto`；共享地图层不感知响应包裹 |
| DTO 坐标字段由 `points` 改为 `boundary` | `types.ts#HarborZoneDto` 声明传输字段；`adapters/normalize-zone.ts#normalizeZone` 从 `dto.boundary` 读取并解析坐标 | `MapZoneModel.coordinates` 及 `MapCanvasExpose.replaceZones()` 契约保持不变 |

`HarborApiResponse` 与 `HarborZoneDto` 是模块拥有的后端传输契约；后端字段和包裹结构不进入 Vue 公开接口，也不扩散到共享地图组件。

### 围栏 DTO 归一化

入口为 `normalize-zone.ts#normalizeZone`。

1. 仅接受 `enabled === '0'` 且 `zone_id` 去除首尾空白后非空的 DTO。
2. 将 `boundary` 按 `_` 分隔为点，再按 `,` 转为数字坐标。
3. 仅保留恰好两个有限数字的点；有效点少于 3 个时返回 `null`。
4. 输出 `{ id: dto.zone_id, coordinates }`，满足 `MapZoneModel` 的最小公开契约。

### 并发请求淘汰

`setZonesVisible()` 每次调用递增 `requestVersion`。异步请求、清除或替换完成后，仅当前版本可以继续产生可见结果；旧调用返回 `{ status: 'superseded' }`，避免较早请求覆盖较新的显隐意图。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 透传给 `MapCanvas` 的初始缩放级别 |

### Emits

| 名称 | 参数 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏成功显示、成功隐藏或请求/渲染失败时发出 |

### Slots

| 名称 | 语义 |
| --- | --- |
| `toolbar` | 渲染在地图组件之前的工具栏内容 |

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

## 数据转换与责任分层

```text
fetchHarborZones()
  → HarborApiResponse.code + HarborApiResponse.data.items
  → HarborZoneDto.boundary
  → normalizeZone(dto)
  → MapZoneModel[]
  → MapCanvasExpose.replaceZones(zones)
  → HarborZoneResult + zoneStatusChange
```

- service 层拥有后端响应包裹的类型边界。
- `setZonesVisible()` 拥有响应状态判断、`data.items` 解包、并发淘汰和命令结果映射。
- adapter 层拥有后端字段到地图坐标模型的语义转换与无效 DTO 过滤。
- 共享地图组件只接收 `MapZoneModel[]`，不依赖 `HarborApiResponse` 或 `HarborZoneDto`。

## 直接公共依赖

Provider：`packages/shared-ui/src/map-canvas/public.ts`。

| 公开 symbol | HarborMap 实际使用 |
| --- | --- |
| `MapZoneModel` | `id: string` 与 `coordinates: Array<[number, number]>`，作为归一化输出 |
| `MapCanvasExpose.replaceZones` | 接收 `MapZoneModel[]`，返回 `success`、`empty` 或 `render-error` 命令结果 |
| `MapCanvasExpose.clearZones` | 隐藏路径清除地图围栏 |

## 跨功能风险

- 后端响应包裹必须在 `HarborApiResponse` 与 `setZonesVisible()` 的取值路径保持一致；否则显示路径会在进入 DTO 归一化前失效。
- 后端坐标字段必须在 `HarborZoneDto` 与 `normalizeZone()` 的读取字段保持一致；否则有效围栏会被阻断在归一化边界。
- 后端契约变化应止于 service、DTO、组件解包和 adapter；`MapZoneModel` 或 Vue 公开接口没有同义变化时，不应随传输结构改名。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件显隐与公开接口 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件单元 | 隐藏不请求后端、并发请求只保留最新结果、Props/Emits/Slots/Expose 的预期覆盖 | 真实后端响应、共享地图实现和调用方状态 | Vue 公开契约或显隐结果语义变化 |
| DTO 归一化 | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` 与模块测试入口 | 单元/类型 | DTO 过滤、`boundary` 解析和 `MapZoneModel` 输出边界的预期覆盖 | 后端是否持续提供合法坐标字符串 | DTO 字段、分隔格式或过滤规则变化 |
| 后端响应包裹 | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#HarborApiResponse` 与 `HarborMap.vue#setZonesVisible` | 类型/组件单元 | `data.items` 解包位置及 DTO 列表进入适配层的预期覆盖 | 线上接口兼容性和服务端字段语义 | 响应 code、包裹层级或 DTO schema 再次变化 |
| 共享地图契约 | `packages/shared-ui/src/map-canvas/public.ts` | 类型/跨 owner | HarborMap 使用的 `MapZoneModel` 与 `MapCanvasExpose` 声明边界 | provider 内部渲染行为 | `MapZoneModel`、`replaceZones` 或 `clearZones` 契约变化 |

## 模块内事实冲突

`HarborMap.spec.ts` 的并发用例 fixture 仍使用旧响应形状 `data: HarborZoneDto[]` 和旧 DTO 字段 `points`；该测试期望与 `dto-change.diff` 描述的 `data.items`、`boundary` 生产契约不一致，因此当前测试入口不能作为新后端契约 fixture 的一致性证据。

## 文档维护信息

- Owner：`apps/harbor-system`
- 主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`
- 后端契约吸收入口：`services/harbor-api.ts#HarborApiResponse`、`types.ts#HarborZoneDto`、`adapters/normalize-zone.ts#normalizeZone`
- 跨 owner 公共契约：`packages/shared-ui/src/map-canvas/public.ts`

