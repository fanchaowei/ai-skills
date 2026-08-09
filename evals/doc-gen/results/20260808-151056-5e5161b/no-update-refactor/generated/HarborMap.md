---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 负责港区电子围栏的显隐编排、接口数据规范化、地图画布更新与并发请求淘汰。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  request_supersession:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 请求竞争与结果淘汰

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

# HarborMap - 港区电子围栏组件

## 模块概述

`HarborMap` 在 `MapCanvas` 上编排港区电子围栏的显示与隐藏。显示链路请求围栏 DTO、过滤并转换有效几何数据、替换画布围栏；隐藏链路直接清空画布。组件通过递增请求版本淘汰部分过期异步结果，并把稳定结果映射为公开返回值与状态事件。

## 模块边界

### Owned

- `apps/harbor-system/src/components/harbor-map/HarborMap.vue`：组件公开契约、显隐编排、请求版本与结果映射。
- `apps/harbor-system/src/components/harbor-map/types.ts`：围栏 DTO、公开操作结果和组件 Expose 类型。
- `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts`：港区围栏查询入口及响应类型。
- `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts`：DTO 到地图围栏模型的规范化。
- `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`：模块预期与稳定验证入口。

### Direct public dependency

- `packages/shared-ui/src/map-canvas/public.ts`：提供模块实际使用的 `MapCanvasExpose` 与 `MapZoneModel` 公开契约。

### Excluded

- `apps/harbor-system/src/pages/HarborPage.vue` 是组件调用方；其状态、失败回退和测试不属于 `HarborMap` 模块事实。

边界证据来自 `HarborMap.vue` 的相对 import、类型引用和 `MapCanvas` 公开契约引用；当前证据不存在 owned/shared 冲突。

## 功能目录

### 围栏显隐编排

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 每次调用先递增 `requestVersion`，并读取 `MapCanvasExpose`；画布引用不可用时返回 `render-error`。
- `visible=false` 时调用 `clearZones()`。清理完成且请求未过期时发出 `hidden`，返回 `{ status: 'success', count: 0 }`；清理失败时发出 `error` 并返回 `render-error`。
- `visible=true` 时调用 `fetchHarborZones()`；仅响应码为 `200` 的数据进入转换，否则发出 `error` 并返回 `request-error`。
- 没有有效围栏时返回 `empty`，不调用 `replaceZones()`。
- `replaceZones()` 成功时发出 `visible` 并返回实际数量；依赖返回 `empty` 时映射为 `empty`，其他非成功结果映射为 `render-error`，并发出 `error`。
- 可见链路中的未分类异常映射为 `request-error`；若异常结果已过期，则返回 `superseded`。

### 围栏数据规范化

入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`

- 只接受 `enabled === '0'` 且 `zone_id` 去除空白后非空的 DTO。
- `points` 使用下划线分隔坐标点、逗号分隔数值；非二元或非有限数值坐标会被过滤。
- 少于三个有效坐标点时返回 `null`；有效数据转换为 `{ id, coordinates }` 的 `MapZoneModel`。
- 编排层批量调用 `normalizeZone()` 并过滤 `null`，只把有效模型交给地图画布。

### 请求竞争与结果淘汰

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 所有显隐调用共享单调递增的 `requestVersion`。
- 请求完成、画布替换完成或清理成功后，如果当前版本已不是最新版本，则返回 `superseded`，不提交对应的成功事件。
- 可见链路的异常处理也会先检查版本；隐藏链路的 `clearZones()` 失败分支不会再次检查版本，而是直接发出 `error` 并返回 `render-error`。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 作为 `initial-zoom` 传给 `MapCanvas`。 |

### Emits

| 事件 | 载荷 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏成功显示、成功清空或请求/渲染错误时发出；`empty`、`superseded` 以及画布引用缺失不会发出对应状态。 |

### Slots

| 名称 | Props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的工具栏内容。 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 的公开结果为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 直接公共依赖

### `@shared/ui/map-canvas`

模块渲染 `MapCanvas`，并使用以下最小公开契约：

- `MapCanvasExpose.clearZones(): Promise<void>`：隐藏链路清空围栏。
- `MapCanvasExpose.replaceZones(zones: MapZoneModel[]): Promise<MapZoneCommandResult>`：显示链路替换有效围栏，并返回成功数量、空结果或渲染错误。
- `MapZoneModel`：包含 `id: string` 与 `coordinates: Array<[number, number]>`，由 `normalizeZone()` 构建。

本文档不记录地图画布 provider 的内部实现。

## 数据转换与责任分层

显示链路的语义转换为：

1. `fetchHarborZones()` 返回 `{ code, data: HarborZoneDto[] }`。
2. 编排层只接纳 `code === 200` 的 DTO 列表，否则映射为 `request-error`。
3. `normalizeZone()` 执行业务启用标记、标识和坐标有效性过滤，产出 `MapZoneModel | null`。
4. 编排层过滤无效模型；空集合映射为 `empty`，非空集合交给 `replaceZones()`。
5. 地图结果再映射为 `HarborZoneResult` 和可选的 `zoneStatusChange` 事件。

隐藏链路不请求围栏数据，直接调用 `clearZones()`。

## 验证入口与证明范围

稳定入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`

| 检查层级 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- |
| 组件交互 | 组件测试 | 隐藏操作不请求围栏、调用 `clearZones()`，并返回计数为 0 的成功结果。 | `clearZones()` 失败、画布引用缺失及过期隐藏失败分支的语义。 | 修改隐藏错误映射或画布挂载方式时增加覆盖。 |
| 并发编排 | 组件测试 | 两个并发显示请求中，较旧结果被淘汰，只有最新结果进入 `replaceZones()`。 | 请求异常、非 200 响应、渲染非成功结果和三次以上交错调用。 | 修改请求版本、异常映射或渲染提交时增加覆盖。 |
| 公开契约 | 组件测试 | `initialZoom`、`toolbar` slot、`setZonesVisible` expose 与 `zoneStatusChange('hidden')` 的预期使用方式。 | Props 默认值、全部事件载荷和全部公开返回分支。 | 修改 Props、Emits、Slots 或 Expose 时同步扩充契约测试。 |

`normalizeZone()` 当前没有独立测试入口；现有组件测试只通过有效 DTO 间接覆盖其成功转换路径，不能覆盖无效启用标记、空标识、非法坐标或点数不足分支。

## 文档维护信息

- Owner：`apps/harbor-system`
- 模块类型：Vue 组件，详细粒度。
- 文档事实范围：目标组件 owned 文件、模块内部测试及 `MapCanvas` 的最小直接公共契约。
- 维护规则：调用方实现无条件排除；公开契约、稳定路径或核心 symbol 变化时同步更新导航与正文。
