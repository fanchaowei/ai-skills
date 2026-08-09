---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: "HarborMap"
module_type: "component"
owner: "apps/harbor-system"
audience: ai
read_mode: progressive
depth: "detailed"
summary: "HarborMap 通过公开方法编排港区电子围栏的请求、规范化、地图替换或清除，并返回稳定结果状态。"

feature_index:
  geofence_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏 DTO 规范化

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  data_flow: 数据转换与责任分层
  diagnostics: 问题排查与症状索引

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 电子围栏地图组件

## 模块概述

HarborMap 是 `apps/harbor-system` 拥有的 Vue 组件。它向外暴露 `setZonesVisible`，在显示时获取港区围栏、转换为共享地图模型并替换画布内容，在隐藏时清空画布；调用结果通过 `HarborZoneResult` 返回，成功显示、成功隐藏和错误还会通过组件事件通知。

## 模块边界

| 路径 | 角色 | 当前职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 组件公开契约、显隐编排、并发版本淘汰、结果与事件映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | DTO、公开结果联合类型与 expose 接口 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 港区围栏请求入口与响应形状 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 港区 DTO 到地图围栏模型的规范化 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块稳定验证入口及其预期覆盖范围 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | HarborMap 实际使用的地图围栏模型与画布 expose 契约 |

`apps/harbor-system/src/pages/HarborPage.vue` 是 HarborMap 的 caller，始终排除在模块边界之外；其实现、状态、测试、回退和排障步骤不属于 HarborMap 模块事实。

## 功能目录

### 电子围栏显隐编排

真实入口是 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。

- `setZonesVisible(false)` 不请求围栏数据，直接调用地图画布的 `clearZones()`；当前调用仍是最新版本时，发出 `zoneStatusChange: hidden` 并返回 `{ status: 'success', count: 0 }`。
- `setZonesVisible(true)` 调用 `fetchHarborZones()`；仅当响应 `code === 200` 时继续，将 `data` 逐项交给 `normalizeZone()` 并丢弃 `null`，然后调用地图画布的 `replaceZones()`。
- 每次调用递增 `requestVersion`。显示链路在请求完成和地图替换完成后检查版本，隐藏链路在清除完成后检查版本；被更新调用取代时返回 `{ status: 'superseded' }`，不发布成功事件。
- 地图引用不可用时直接返回 `{ status: 'render-error' }`。请求抛错或响应码异常映射为 `request-error`；没有可用围栏映射为 `empty`；地图替换的非成功结果映射为 `empty` 或 `render-error`。

稳定结果与事件关系：

| 结果 | 典型来源 | 事件 |
| --- | --- | --- |
| `success`，带 `count` | 清除成功或地图替换成功 | 隐藏发 `hidden`；显示发 `visible` |
| `empty` | 规范化后无围栏，或画布返回 empty | 规范化后为空不发事件；画布返回 empty 时发 `error` |
| `request-error` | 响应码非 200 或请求异常 | 发 `error`；已被取代的请求异常返回 `superseded` |
| `render-error` | 地图引用缺失、清除异常或地图替换失败 | 引用缺失不发事件；清除或替换失败发 `error` |
| `superseded` | 异步结果不再属于最新调用 | 不发成功事件 |

### 围栏 DTO 规范化

真实入口是 `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。

- 仅处理 `enabled === '0'` 且去除空白后 `zone_id` 非空的 DTO，否则返回 `null`。
- `points` 使用 `_` 分隔点、`,` 分隔坐标分量，并将分量转换为数字。
- 非二元或包含非有限数的坐标点会被过滤；剩余有效坐标少于 3 个时返回 `null`。
- 成功结果为 `{ id: dto.zone_id, coordinates }`，符合共享 `MapZoneModel` 的最小公开形状。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 初始缩放值，由 HarborMap 转交给地图画布 |

### Emits

| 名称 | 载荷 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏成功显示、成功隐藏，或请求/渲染链路进入错误结果时通知外部 |

### Slots

| 名称 | Slot props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的工具区域 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 当前可能为：

```ts
{ status: 'success'; count: number }
| { status: 'empty' }
| { status: 'request-error' }
| { status: 'render-error' }
| { status: 'superseded' }
```

## 直接公共依赖

| Provider | HarborMap 使用的公开契约 | 模块内使用入口 |
| --- | --- | --- |
| `packages/shared-ui/src/map-canvas/public.ts` | `MapZoneModel` 的 `id`、`coordinates`；`MapCanvasExpose.clearZones()`；`MapCanvasExpose.replaceZones(zones)` 及其 `success`、`empty`、`render-error` 结果 | `normalizeZone()`、`setZonesVisible()` |

HarborMap 只依赖这些公开形状和方法；共享地图组件的内部渲染、状态和测试不属于本模块文档。

## 数据转换与责任分层

1. `fetchHarborZones()` 提供 `{ code, data: HarborZoneDto[] }`。
2. `normalizeZone()` 负责启用标记、标识和坐标有效性，将 DTO 收敛为 `MapZoneModel | null`。
3. `setZonesVisible()` 过滤 `null`、处理空集合和异步版本淘汰，再调用共享地图画布。
4. `MapCanvasExpose` 返回地图命令结果；HarborMap 将其收敛为 `HarborZoneResult`，并在确定的成功或错误分支发布组件事件。

## 问题排查与症状索引

| 症状或结果 | 第一检查点 | 下一验证入口 |
| --- | --- | --- |
| `request-error` | `services/harbor-api.ts#fetchHarborZones` 的抛错或非 200 响应，以及 `HarborMap.vue#setZonesVisible` 的响应映射 | 为 `HarborMap.spec.ts` 增加请求异常和非 200 组件用例 |
| `empty` | `adapters/normalize-zone.ts#normalizeZone` 的过滤条件，以及 `replaceZones()` 的公开返回值 | 增加 adapter 单元用例和组件 empty 分支用例 |
| `render-error` | `mapCanvasRef` 是否存在，以及 `clearZones()` / `replaceZones()` 的公开结果或异常 | 在 `HarborMap.spec.ts` 覆盖引用缺失、清除异常和替换失败 |
| 旧异步结果覆盖新结果 | `HarborMap.vue#requestVersion` 与请求、替换后的版本检查 | `HarborMap.spec.ts` 的“keeps only the latest visible request result”用例 |

第一检查点只定位模块内责任边界，不等同于已确认根因。

## 验证入口与证明范围

最小现有验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。

| 改动层级 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- |
| 组件公开契约与显隐编排 | Vue 组件测试 | 隐藏时不请求并调用清除；两个显示请求只采用最新结果；`initialZoom`、`toolbar`、`setZonesVisible` 和 `zoneStatusChange` 的基本可观察契约 | 本次任务已执行通过；请求错误、空数据、地图引用缺失、清除失败、替换 empty/render-error 等未覆盖分支 | 修改结果或事件映射、错误分支、并发检查位置时扩充组件用例 |
| DTO 规范化 | 现有组件测试的间接覆盖 | 最新请求的有效 DTO 可进入一次地图替换 | 所有无效 DTO、混合有效/无效坐标和边界点数规则 | 修改 `normalizeZone()` 时增加独立 adapter 单元测试 |
| 共享地图公开契约 | 类型/集成边界 | 现有公开声明给出 HarborMap 所需类型与 expose 形状 | 共享地图内部实现或真实渲染效果 | `MapCanvasExpose` 或 `MapZoneModel` 变化时扩大到 shared-ui 类型检查和集成验证 |

测试文件只描述预期和覆盖范围，不代表当前实现必然符合预期，也不代表本次已执行测试。

## 文档维护信息

- owner：`apps/harbor-system`
- 规范版本：`ai-module-spec v3`
- 维护依据：HarborMap 自有生产代码、模块内测试，以及目标模块真实引用的共享地图公开声明
- caller 排除：`apps/harbor-system/src/pages/HarborPage.vue`

