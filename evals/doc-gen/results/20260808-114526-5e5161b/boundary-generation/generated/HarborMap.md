---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: "HarborMap"
module_type: "component"
owner: "apps/harbor-system"
audience: ai
read_mode: progressive
depth: "detailed"
summary: "HarborMap 通过公开显隐命令获取、归一化并渲染港区电子围栏，同时用版本号淘汰过期异步结果。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据归一化
  zone_request:
    entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones
    body_section: 围栏数据获取

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  diagnostics: 问题排查与状态矩阵
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港区地图组件

## 模块概述

`HarborMap` 是 `apps/harbor-system` 内负责港区地图与电子围栏的 Vue 组件。组件把 `initialZoom` 传给共享地图画布，通过暴露的 `setZonesVisible()` 命令控制电子围栏：显示时获取港区围栏 DTO、转换为地图模型并替换画布围栏，隐藏时直接清空画布围栏。每次命令都会递增请求版本，异步阶段只允许最新版本继续产生公开结果。

## 模块边界

### Owned 文件

| 路径 | 角色与边界证据 |
| --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 组件主入口；拥有 Props、Emits、Slots、Expose、显隐编排和请求版本状态。 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | 模块专属 DTO、暴露接口和公开命令结果类型。 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | 把港区围栏 DTO 转换为地图围栏模型的专属 adapter。 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | 组件直接调用的港区围栏 service 入口与响应类型。 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 模块内部组件测试；只证明测试表达的预期与覆盖范围。 |

### 边界外文件

- `packages/shared-ui/src/map-canvas/public.ts` 是直接公共依赖的声明，不归 `HarborMap` 所有；本文只记录本模块实际使用的最小公开契约。
- 使用 `HarborMap` 的页面或父组件属于 `caller`，无条件排除。其状态、失败回退、测试和修改方式均不是本模块事实。

边界确认结果：用户指定目录内不存在多个独立所有者；生产代码的 import 方向能够闭合到上述 owned 文件与一个直接公共依赖，不需要读取调用方才能解释模块行为。

## 功能目录

### 电子围栏显隐编排

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 每次调用先递增模块内 `requestVersion`；取得画布 expose 失败时返回 `{ status: 'render-error' }`。
- `visible === false` 时不请求围栏数据，直接调用 `MapCanvasExpose.clearZones()`。清理完成且版本仍为最新时发出 `zoneStatusChange: 'hidden'`，返回 `{ status: 'success', count: 0 }`。
- `visible === true` 时调用 `fetchHarborZones()`；响应码不是 `200` 时发出 `error` 事件并返回 `request-error`。
- 有效响应经 `normalizeZone()` 转换并过滤无效项；没有可渲染围栏时返回 `empty`，不调用 `replaceZones()`。
- 有围栏时调用 `MapCanvasExpose.replaceZones()`；成功后发出 `visible` 事件并返回画布报告的数量。画布返回 `empty` 时映射为模块 `empty`，其他非成功结果映射为 `render-error`，两者都会发出 `error` 事件。
- 获取或渲染异步阶段完成后若版本已过期，则返回 `superseded`，并抑制该命令后续的成功/错误事件；版本检查发生在 awaited 依赖调用之后，不能撤销依赖已经产生的副作用。

### 围栏数据归一化

入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`

- 输入是 `HarborZoneDto`；只有 `enabled === '0'` 且 `zone_id` 去除首尾空白后非空的记录进入坐标转换。
- `points` 以 `_` 分隔点、以 `,` 分隔数值；非二元或非有限数值坐标被过滤。
- 少于 3 个有效坐标时返回 `null`；否则返回 `{ id: dto.zone_id, coordinates }` 的 `MapZoneModel`。
- 主组件用 `map(normalizeZone).filter(zone !== null)` 吸收无效记录，adapter 不负责请求、画布调用或公开事件。

### 围栏数据获取

入口：`apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones`

- 公开返回 `Promise<HarborApiResponse>`，响应结构是 `{ code: number, data: HarborZoneDto[] }`。
- 当前 service 实现返回 `{ code: 200, data: [] }`；组件负责解释响应码、归一化数据以及把异常映射为公开命令结果。

## 当前公开契约

### Props

| 名称 | 类型 | 必填 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `initialZoom` | `number` | 否 | `12` | 作为 `initial-zoom` 传给内部 `MapCanvas`。 |

### Emits

| 事件 | 负载 | 发出条件 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 最新显示命令渲染成功时发出 `visible`；最新隐藏命令清理成功时发出 `hidden`；已识别的请求或渲染失败路径发出 `error`。`empty`、`superseded` 和画布引用缺失路径本身不保证发出事件。 |

### Slots

| 名称 | Slot props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的工具栏区域。 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 的公开结果为：

- `{ status: 'success'; count: number }`：显示或隐藏命令成功；隐藏成功的 `count` 为 `0`。
- `{ status: 'empty' }`：归一化后没有可渲染围栏，或画布替换结果为 `empty`。
- `{ status: 'request-error' }`：响应码不是 `200`，或最新显示请求/转换阶段抛出异常。
- `{ status: 'render-error' }`：画布引用不可用、隐藏清理抛出异常，或画布替换返回非成功且非 `empty` 的结果。
- `{ status: 'superseded' }`：异步结果完成时已有更新命令取得更高请求版本。

组件没有默认 slot，也没有公开除 `setZonesVisible` 以外的 expose 成员。

## 直接公共依赖

Provider：`packages/shared-ui/src/map-canvas/public.ts`

| 公开 symbol | HarborMap 实际使用的最小契约 | 模块内入口 |
| --- | --- | --- |
| `MapZoneModel` | `{ id: string; coordinates: Array<[number, number]> }`；作为归一化结果和 `replaceZones()` 输入。 | `normalizeZone`、`setZonesVisible` |
| `MapCanvasExpose.clearZones` | `(): Promise<void>`；隐藏围栏时清空画布。 | `setZonesVisible(false)` |
| `MapCanvasExpose.replaceZones` | `(zones: MapZoneModel[]): Promise<MapZoneCommandResult>`；显示围栏时替换画布数据。 | `setZonesVisible(true)` |
| `MapZoneCommandResult` | `success(count)`、`empty` 或 `render-error`；由组件映射为 `HarborZoneResult` 和事件。 | `setZonesVisible(true)` |

本文不复制 `MapCanvas` provider 的内部实现。

## 数据转换与责任分层

```text
fetchHarborZones()
  -> HarborApiResponse / HarborZoneDto[]
  -> normalizeZone(dto)
  -> MapZoneModel | null
  -> 过滤 null 后的 MapZoneModel[]
  -> MapCanvasExpose.replaceZones()
  -> MapZoneCommandResult
  -> HarborZoneResult + zoneStatusChange
```

- service 层只提供港区响应结构和获取入口。
- adapter 层负责记录启用条件、坐标解析与最小多边形点数，不解释画布结果。
- 组件层拥有请求版本、显隐分支、错误映射、事件和公开命令结果。
- 共享地图画布拥有清理/替换命令的渲染结果；本模块只消费其公开 expose 契约。

## 问题排查与状态矩阵

### 公开结果矩阵

| 场景 | 返回结果 | 事件 | 第一检查点 |
| --- | --- | --- | --- |
| 画布 expose 不可用 | `render-error` | 无 | `HarborMap.vue#mapCanvasRef` |
| 隐藏清理成功且仍为最新命令 | `success(count: 0)` | `hidden` | `MapCanvasExpose.clearZones` |
| 隐藏清理完成后已出现更新命令 | `superseded` | 无 | `HarborMap.vue#requestVersion` |
| 隐藏清理抛出异常 | `render-error` | `error` | `MapCanvasExpose.clearZones` |
| 显示响应码非 `200` | `request-error` | `error` | `harbor-api.ts#fetchHarborZones` |
| 最新显示流程抛出异常 | `request-error` | `error` | `HarborMap.vue#setZonesVisible` |
| 归一化后无有效围栏 | `empty` | 无 | `normalize-zone.ts#normalizeZone` |
| 画布替换返回 `empty` | `empty` | `error` | `MapCanvasExpose.replaceZones` |
| 画布替换返回 `render-error` | `render-error` | `error` | `MapCanvasExpose.replaceZones` |
| 显示渲染成功且仍为最新命令 | `success(count)` | `visible` | `HarborMap.vue#setZonesVisible` |
| 显示流程异步结果已过期 | `superseded` | 无 | `HarborMap.vue#requestVersion` |

第一检查点用于定位责任层，不代表根因。下一验证入口是 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`；adapter、service 或共享画布契约变化时需按“验证入口与证明范围”扩大检查。

## 跨功能风险

- `requestVersion` 是显示和隐藏命令共享的并发不变量；它淘汰过期命令的后续公开结果与事件，但 `clearZones()` 或 `replaceZones()` 已经发生的副作用不会被回滚。改变 await 与版本检查的顺序时，需要同时验证公开结果和真实画布状态。
- 隐藏分支的异常处理不会在发出 `error` 前再次检查版本。因此，较旧隐藏命令的 `clearZones()` 若在更新命令开始后抛出异常，当前实现仍返回 `render-error` 并发出 `error`；维护并发语义时需显式保留或调整这一现状。
- `enabled === '0'` 是当前 adapter 接受围栏的条件。修改该值的语义会同时改变空结果、画布输入数量和公开显示结果。
- `normalizeZone()` 返回的 `id` 保留原始 `zone_id`，非空判断使用的是 `trim()` 结果但不会回写修剪后的值；依赖标识符精确值的改动需覆盖这一行为。

## 验证入口与证明范围

稳定入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`

| 改动层级 | 检查类型 | 当前测试能证明的预期与覆盖范围 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- |
| 隐藏编排 | 组件测试 | 隐藏命令不调用 `fetchHarborZones()`、调用一次 `clearZones()`，并期望返回 `success(count: 0)`。 | 清理异常、画布引用缺失、过期隐藏结果。 | 改动隐藏错误映射、画布挂载或并发规则时增加对应组件用例。 |
| 最新请求淘汰 | 组件测试 | 两个并发显示请求中，较新请求期望成功，较旧请求期望 `superseded`，并且只调用一次 `replaceZones()`。 | 三个以上交错命令、显示与隐藏交错、替换完成后的过期路径、异常交错。 | 改动 `requestVersion` 或异步阶段顺序时扩展并发矩阵。 |
| Vue 公开契约 | 组件测试 | 传入 `initialZoom` 可由 wrapper 读取；`toolbar` slot 可渲染；`setZonesVisible` 可从组件实例调用；隐藏成功期望发出 `hidden`。 | 默认值 `12` 的传递、`visible`/`error` 事件、全部 `HarborZoneResult` 分支。 | 修改 Props、Emits、Slots、Expose 或结果联合类型时扩展契约用例。 |
| adapter | 单元或组件测试 | 当前组件测试中的有效 DTO 可进入一次 `replaceZones()`。 | 禁用记录、空白 ID、非法坐标、少于 3 个坐标、ID 空白保留规则的独立边界。 | 修改 `normalizeZone()` 时增加 adapter 单元测试。 |
| service | 单元或集成测试 | 组件测试通过 mock 证明组件按 `fetchHarborZones()` 的异步结果编排。 | 当前 service 实现、真实传输、响应 schema 兼容性或异常来源。 | 修改 service 实现或响应结构时增加 service/集成检查。 |
| 共享画布契约 | 类型、组件或跨 owner 集成检查 | stub expose 证明组件依赖 `clearZones()` 与 `replaceZones()` 的调用形状。 | `MapCanvas` 的真实渲染、真实 `initial-zoom` 行为和跨 owner 运行时兼容性。 | 修改 `packages/shared-ui/src/map-canvas/public.ts` 或真实画布组件时增加共享库类型检查与集成验证。 |

测试文件表达稳定预期和覆盖范围，不代表当前实现必然符合预期，也不表示本次已执行测试。fixture 未提供可确认的项目测试、类型检查或 lint 命令，因此本文不推测命令入口。

## 文档维护信息

- 当前事实入口：`HarborMap.vue`、`types.ts`、`adapters/normalize-zone.ts`、`services/harbor-api.ts`。
- 验证范围入口：`__tests__/HarborMap.spec.ts`。
- 直接依赖声明入口：`packages/shared-ui/src/map-canvas/public.ts`。
- 公开契约变化时同步核对 Props、Emits、Slots、Expose 四类接口；电子围栏链路变化时同步核对 feature index、状态矩阵、依赖映射与验证扩大条件。
