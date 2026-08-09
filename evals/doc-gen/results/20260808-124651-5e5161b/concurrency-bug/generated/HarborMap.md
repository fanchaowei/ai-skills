---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 公开电子围栏显隐命令，负责请求、规范化、地图命令编排及并发结果淘汰。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  diagnostics: 问题排查与故障边界
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 电子围栏地图组件

## 模块概述

`HarborMap` 通过公开方法切换电子围栏可见性。显示链路请求围栏数据、过滤并转换有效多边形，再调用共享地图组件替换围栏；隐藏链路直接清除地图围栏。组件使用单调递增的 `requestVersion` 将已过期调用的公开结果标记为 `superseded`。

## 模块边界

| 路径 | 角色 | 当前责任 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 公开契约、显隐编排、错误映射和请求版本判断 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 围栏 DTO、公开结果联合类型和 expose 接口 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 将服务 DTO 转为地图围栏模型 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 提供围栏请求入口及响应类型 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 记录组件公开行为和并发预期的稳定验证入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 提供本模块实际使用的地图命令与数据模型公开声明 |

调用 `HarborMap` 的页面属于 caller，不进入模块事实、诊断或验证范围。

## 功能目录

### 电子围栏显隐编排

入口为 `HarborMap.vue#setZonesVisible`。

- 每次调用先递增 `requestVersion` 并保存本次版本。
- 地图实例不可用时返回 `render-error`。
- 隐藏时调用 `MapCanvasExpose.clearZones()`；当前版本完成后发出 `zoneStatusChange: hidden`，公开结果为 `success` 且 `count` 为 `0`。
- 显示时调用 `fetchHarborZones()`；非 `200` 响应映射为 `request-error`。
- 有效围栏交给 `MapCanvasExpose.replaceZones()`；成功时发出 `zoneStatusChange: visible` 并返回实际 `count`。
- 在请求完成后或地图命令完成后发现版本已过期时，公开结果为 `superseded`。

最小事实链：`setZonesVisible` → `requestVersion` → `fetchHarborZones` / `clearZones` → `normalizeZone` → `MapCanvasExpose.replaceZones` → `HarborZoneResult` → `HarborMap.spec.ts`。

### 围栏数据规范化

入口为 `normalize-zone.ts#normalizeZone`。

- 仅接受 `enabled === '0'` 且非空的 `zone_id`。
- `points` 以 `_` 分隔点、以 `,` 分隔坐标，并丢弃非有限数值坐标。
- 少于三个有效坐标的记录返回 `null`。
- 有效记录转换为共享契约 `MapZoneModel`；显示链路过滤 `null` 后再渲染。

最小事实链：`HarborZoneDto` → `normalizeZone` → `MapZoneModel | null` → `setZonesVisible` 的有效围栏集合 → `HarborMap.spec.ts` 的显示场景。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 传给地图组件的初始缩放级别 |

### Emits

| 名称 | 载荷 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' | 'hidden' | 'error'` | 报告围栏显示、隐藏或错误结果；`superseded` 不对应 emit 值 |

### Slots

| 名称 | 作用域参数 | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染地图上方的工具内容 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 的结构化状态为 `success`、`empty`、`request-error`、`render-error` 或 `superseded`；仅 `success` 携带 `count`。

## 直接公共依赖

`HarborMap` 从 `packages/shared-ui/src/map-canvas/public.ts` 使用以下最小公开契约：

- `MapZoneModel`：传给地图层的 `id` 与坐标数组。
- `MapCanvasExpose.replaceZones(zones)`：替换地图围栏，返回 `success`、`empty` 或 `render-error`。
- `MapCanvasExpose.clearZones()`：清除地图围栏。

该公开契约没有请求版本、取消令牌或条件写入参数；地图命令内部如何提交绘制结果不属于 `HarborMap` 模块事实。

## 数据转换与责任分层

```mermaid
flowchart LR
  A["fetchHarborZones 返回 HarborZoneDto[]"] --> B["normalizeZone 过滤并转换"]
  B --> C["MapZoneModel[]"]
  C --> D["MapCanvasExpose.replaceZones"]
  D --> E["HarborZoneResult 与 zoneStatusChange"]
```

- service 层提供响应码和 DTO 数组。
- adapter 层拥有 DTO 有效性判断与坐标转换。
- 组件层拥有并发版本、空集合、错误状态和公开事件映射。
- 共享地图组件拥有实际清除或替换围栏的副作用。

## 问题排查与故障边界

### 症状：旧请求结果覆盖新请求

| 导航项 | 稳定入口或信号 |
| --- | --- |
| 第一检查点 | `HarborMap.vue#setZonesVisible` 中 `requestVersion` 检查与异步 `replaceZones()` / `clearZones()` 的相对位置 |
| 稳定结构化信号 | 每次 expose 调用返回的 `HarborZoneResult.status`，以及地图公开命令接收的围栏 `id` / 返回的 `MapZoneCommandResult.status` |
| 下一验证入口 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 的并发场景 |

当前并发淘汰能阻止“仍停留在请求阶段”的旧显示请求进入地图命令。故障边界出现在旧调用已经通过版本检查并进入异步地图命令之后：命令完成后的版本检查可以把公开结果标记为 `superseded`，但不能撤销地图层已经发生或仍在完成的清除/替换副作用。因此，`superseded` 只稳定描述该调用的公开结果已过期，不单独证明地图最终数据来自最新调用。

同一边界同时适用于 `replaceZones()` 与 `clearZones()`。地图公开契约不携带版本信息，因而版本判断归组件编排负责，实际副作用提交归地图组件负责；定位时先确认旧命令是否已越过组件的命令前版本检查，再把检查范围扩大到地图命令完成顺序。

## 跨功能风险

- 请求版本只在组件层生效，无法取消已经交给地图组件的异步副作用。
- 旧命令完成后的 `superseded` 返回值与地图最终内容可能不一致；消费方不能用该状态反推地图最终围栏集合。
- 现有并发验证把 `replaceZones` 配置为立即完成，覆盖的是请求阶段乱序，不覆盖两个地图命令自身完成顺序乱序。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| adapter | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 及 `normalizeZone` 的调用场景 | 组件 | 有效 DTO 会进入地图命令，显示结果携带地图返回的数量 | adapter 对全部畸形坐标组合的独立覆盖 | 修改 DTO 过滤或坐标解析规则时增加 adapter 单元入口 | 测试可替换围栏 service 与地图组件 |
| 组件契约 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | `initialZoom`、`toolbar`、`setZonesVisible`、`zoneStatusChange` 的公开形态与隐藏链路预期 | 真实地图渲染和页面调用方行为 | 改动 Props、Emits、Slots、Expose 或共享地图契约时扩大到类型与跨 owner 集成检查 | Vue Test Utils 能挂载组件并取得 expose |
| 并发交互 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 中可控 Promise 场景 | 组件 | 请求阶段乱序时旧调用返回 `superseded`，且只有最新请求进入 `replaceZones` | 旧地图命令已开始后，新旧 `replaceZones` / `clearZones` 乱序完成时的最终地图数据 | 下一验证入口是让旧地图命令先开始、最新命令先完成、旧命令最后完成，并同时观察调用结果与最终应用的围栏 `id` | 地图 stub 能延迟每次命令并暴露最终应用数据 |
| 跨 owner 地图契约 | `packages/shared-ui/src/map-canvas/public.ts` | 类型 / 集成 | 本模块依赖的命令输入输出形态 | 地图命令内部是否支持取消、版本隔离或原子提交 | 修改 `MapCanvasExpose` 或要求保证 latest-only 副作用时扩大到共享地图实现与集成入口 | provider 公开声明保持可检索且由实际组件实现 |

## 文档维护信息

- 事实入口：目标模块生产代码、模块内部测试和共享地图公开声明。
- 边界规则：调用方无条件排除；共享地图只记录本模块真实使用的最小公开契约。
- 诊断维护点：并发控制、地图命令签名、结构化结果或验证入口变化时，同步核对“问题排查与故障边界”和并发验证范围。
