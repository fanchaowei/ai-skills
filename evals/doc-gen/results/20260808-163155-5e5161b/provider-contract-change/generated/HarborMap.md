---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 负责港区电子围栏的显隐编排、数据规范化、地图渲染结果吸收以及对外组件契约。"

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
  dependencies: 直接公共依赖
  data_flow: 数据转换与责任分层
  risks: 跨功能风险
  verification: 验证入口与证明范围

status: active
last_updated: "2026-08-09"
last_updated_by: doc-gen
---

# HarborMap - Vue 组件模块

## 模块概述

HarborMap 将模块内的围栏数据获取与规范化结果交给共享地图画布渲染，并通过 Vue 组件契约向外提供初始缩放、工具栏插槽、状态事件和命令式显隐入口。模块吸收共享地图 provider 的结果联合类型，只暴露 `HarborZoneResult`。

## 模块边界

| 角色 | 路径 | 当前职责 |
| --- | --- | --- |
| owned | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 组件公开契约、显隐编排、并发淘汰、provider 结果映射 |
| owned | `apps/harbor-system/src/components/harbor-map/types.ts` | DTO、Expose 和模块公开结果类型 |
| owned | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | `HarborZoneDto` 到 `MapZoneModel` 的规范化 |
| owned | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | 围栏获取入口及其响应类型 |
| owned | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 模块内稳定验证入口 |
| direct-public-dependency | `packages/shared-ui/src/map-canvas/public.ts` | HarborMap 实际使用的地图模型、命令结果和 Expose 声明 |

调用方不属于 HarborMap 模块边界；其状态管理、失败回退和测试均不构成本模块事实。

## 功能目录

### 电子围栏显隐编排

入口为 `HarborMap.vue#setZonesVisible`。

- `visible: false`：调用 `MapCanvasExpose.clearZones()`；当前调用仍是最新版本时发出 `zoneStatusChange: hidden`，并返回 `{ status: 'success', count: 0 }`。
- `visible: true`：读取 `fetchHarborZones()` 的响应；`code !== 200` 映射为 `request-error`，数据经 `normalizeZone()` 过滤和转换后交给 `replaceZones()`。
- 每次调用递增 `requestVersion`。清除成功、获取完成、地图替换完成以及显示链路异常被捕获后都会核对版本，旧调用返回 `superseded`；`clearZones()` 的 rejection 分支不做第二次版本检查，仍返回 `render-error` 并发出 `error`。
- 地图引用尚未可用时直接返回 `render-error`。
- 规范化后没有可用围栏时返回 `empty`，不会调用 `replaceZones()`。
- provider 返回 `success` 时保留 `count`；返回 `empty` 时映射为模块的 `empty`；返回 `partial` 或 `render-error` 时统一映射为模块的 `render-error`。provider 的 `partial.count` 与 `partial.skipped` 不向 HarborMap 调用方透传。

### 围栏数据规范化

入口为 `normalize-zone.ts#normalizeZone`。

- 只处理 `enabled === '0'` 且去除首尾空白后 `zone_id` 非空的 DTO。
- `points` 先按 `_` 拆分点，再按 `,` 转为数值对；非二维或包含非有限数值的点被过滤。
- 少于 3 个有效坐标时返回 `null`；否则生成 `{ id, coordinates }` 形式的 `MapZoneModel`。
- `setZonesVisible(true)` 会过滤所有 `null` 结果，因此无有效模型时以模块级 `empty` 结束。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 传给地图画布的初始缩放级别 |

### Emits

| 名称 | 载荷 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 地图替换成功后发出 `visible`；清除成功后发出 `hidden`；清除失败、请求失败或 provider 返回非 `success` 结果时发出 `error`。显示链路中被较新调用淘汰的异步结果和已过期的清除成功结果不发出终态事件；清除 rejection 不做版本复核，仍可发出 `error`。地图引用缺失和规范化后为空会直接返回结果，不发出该事件。 |

### Slots

| 名称 | Slot props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的工具栏内容 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 为：

```ts
type HarborZoneResult =
  | { status: 'success'; count: number }
  | { status: 'empty' }
  | { status: 'request-error' }
  | { status: 'render-error' }
  | { status: 'superseded' }
```

HarborMap 不公开 provider 新增的 `partial` 状态；该状态属于直接依赖契约，并在组件边界内被吸收为 `render-error`。

## 直接公共依赖

### `@shared/ui/map-canvas`

HarborMap 只依赖以下公开契约：

| 公开项 | HarborMap 实际使用范围 |
| --- | --- |
| `MapCanvas` | 接收 `initialZoom`，并通过模板 ref 提供地图命令 |
| `MapCanvasExpose.clearZones()` | 隐藏围栏时清空地图覆盖物 |
| `MapCanvasExpose.replaceZones(zones)` | 提交规范化后的 `MapZoneModel[]`，返回 `MapZoneCommandResult` |
| `MapZoneModel` | `{ id: string; coordinates: Array<[number, number]> }` |
| `MapZoneCommandResult` | `success(count)`、`empty`、`partial(count, skipped)` 或 `render-error` |

provider 结果在 `HarborMap.vue#setZonesVisible` 中被收敛：`success` 保留计数，`empty` 保留为空，`partial` 与 `render-error` 统一成为模块的 `render-error`。HarborMap 不依赖 provider 的内部实现。

## 数据转换与责任分层

| 层级 | 输入 | 输出或责任 |
| --- | --- | --- |
| 模块服务 | 无调用参数 | `HarborApiResponse`，包含 `code` 与 `HarborZoneDto[]` |
| 适配器 | `HarborZoneDto` | 有效 `MapZoneModel` 或 `null` |
| 组件编排 | `MapZoneModel[]` | 调用 `replaceZones()`，处理并发版本与 provider 命令结果 |
| 组件公开边界 | `MapZoneCommandResult`、请求或清除异常 | `HarborZoneResult` 与 `zoneStatusChange` |

组件只在规范化后至少存在一个模型时进入地图替换；provider 的 `partial` 细节在组件公开边界被丢弃。

## 状态与错误责任矩阵

| 场景 | 返回结果 | 事件 |
| --- | --- | --- |
| 清除成功且仍为最新调用 | `success(0)` | `hidden` |
| 清除抛错 | `render-error` | `error`；该分支不复核版本 |
| 响应码非 200 或获取抛错 | `request-error` | `error`；若已被淘汰则返回 `superseded` 且不发终态事件 |
| 无有效规范化结果 | `empty` | 无 |
| provider `success(count)` | `success(count)` | `visible` |
| provider `empty` | `empty` | `error` |
| provider `partial(count, skipped)` | `render-error` | `error` |
| provider `render-error` | `render-error` | `error` |
| 显示链路结果或清除成功结果已被较新调用取代 | `superseded` | 无终态事件 |
| 地图 ref 不可用 | `render-error` | 无 |

## 跨功能风险

- `requestVersion` 同时约束显示与隐藏链路，但清除 rejection 分支没有版本复核；该分支可能在较新调用开始后继续发出 `error`。调整异步阶段时需要保持各成功与异常出口的版本语义明确。
- provider 的 `partial` 表示部分渲染并携带 `count`、`skipped`，但 HarborMap 对外只报告 `render-error`。依赖部分成功明细的需求不能从现有 Expose 契约获得。
- 适配器仅接受 `enabled === '0'`；上游编码语义变化会直接改变可渲染围栏集合。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| 组件显隐与并发 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | 隐藏不获取围栏并调用清除；并发显示仅保留最新请求结果 | 请求异常、清除异常及 provider 各非成功分支的映射 | 修改 `requestVersion` 检查点、异步阶段或错误映射时增加对应分支覆盖 | 使用可提供 `clearZones`、`replaceZones` 的 MapCanvas stub，并可控制围栏服务 Promise |
| Vue 公开契约 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件契约测试 | `initialZoom`、`toolbar` slot、Expose 方法及隐藏成功事件的预期形态 | `visible`、`error` 的全部触发条件和返回联合类型的全部成员 | 修改 Props、Emits、Slots、Expose 或 provider 结果联合类型时扩大契约覆盖 | Vue Test Utils 能挂载组件并访问公开实例与 emitted 记录 |
| 数据规范化 | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` | 类型与针对性单元检查入口 | 可定位 DTO 过滤、坐标解析和最少点数规则 | 现有组件测试不能隔离证明所有无效输入组合 | 修改 DTO 编码、分隔符、坐标约束或 `MapZoneModel` 时增加适配器级覆盖 | provider 的 `MapZoneModel` 公开声明可用 |
| 跨 owner provider 契约 | `packages/shared-ui/src/map-canvas/public.ts` 与 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` | 类型与组件契约检查 | 可核对 HarborMap 对 `MapZoneCommandResult` 每个成员的吸收位置 | 仅靠现有测试不能覆盖新增 `partial` 的运行时映射 | provider 增删状态或调整字段时，对每个目标模块实际使用分支增加契约覆盖 | 共享库公开声明与应用依赖解析保持一致 |

## 文档维护信息

- owner：`apps/harbor-system`
- 主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- 公开类型：`apps/harbor-system/src/components/harbor-map/types.ts`
- 直接 provider 契约：`packages/shared-ui/src/map-canvas/public.ts`
- 文档只维护当前模块事实；调用方行为、provider 内部实现和某次验证执行状态不写入本文档。
