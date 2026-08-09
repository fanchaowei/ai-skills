---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: complex
summary: HarborMap 负责港区围栏数据获取、标准化、显隐与地图渲染编排，并通过组件公开契约提供显隐和受限围栏高亮入口。

feature_index:
  zone_visibility:
    entry: "apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible"
    body_section: 电子围栏显隐编排
  restricted_zone_highlight:
    entry: "apps/harbor-system/src/components/harbor-map/HarborMap.vue#highlightRestrictedZone"
    body_section: 受限围栏高亮公开入口
  zone_normalization:
    entry: "apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone"
    body_section: 围栏数据标准化
  latest_request_wins:
    entry: "apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible"
    body_section: 最新请求生效

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  diagnostics: 问题排查与状态责任
  data_flow: 数据转换与责任分层
  removal: 删除与保留边界

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港区围栏地图组件

## 模块概述

HarborMap 是 `apps/harbor-system` 内的 Vue 组件模块。它获取港区围栏 DTO，将有效数据转换为共享地图接受的模型，编排围栏显隐和并发结果淘汰，并把稳定结果、状态事件及命令方法暴露给组件使用者。

## 模块边界

| 角色 | 路径 | 模块内职责 |
| --- | --- | --- |
| owned | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 组件公开契约、显隐编排、请求版本控制和地图命令调用 |
| owned | `apps/harbor-system/src/components/harbor-map/types.ts` | 港区围栏 DTO、命令结果和 Expose 类型 |
| owned | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | 提供 `fetchHarborZones()` 数据入口 |
| owned | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | 将 `HarborZoneDto` 标准化为共享地图模型 |
| owned | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 记录组件公开行为、并发淘汰和新增公开方法的稳定验证入口 |
| direct-public-dependency | `packages/shared-ui/src/map-canvas/public.ts` | 提供 `MapZoneModel`、`MapZoneCommandResult` 与 `MapCanvasExpose` 公开声明 |

## 功能目录

### 电子围栏显隐编排

入口为 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。

- 每次调用先递增模块内 `requestVersion`，并要求 `mapCanvasRef` 已取得 `MapCanvasExpose`；地图引用不存在时返回 `{ status: 'render-error' }`。
- `visible` 为 `false` 时不请求围栏数据，而是调用 `clearZones()`；当前请求仍为最新时触发 `zoneStatusChange('hidden')`，返回 `{ status: 'success', count: 0 }`。
- `visible` 为 `true` 时调用 `fetchHarborZones()`，要求响应 `code === 200`，随后使用 `normalizeZone()` 转换并过滤无效围栏，再调用 `replaceZones()`。
- 没有有效围栏时返回 `{ status: 'empty' }`；共享地图返回成功时触发 `zoneStatusChange('visible')` 并透传成功数量。
- 请求、响应码或地图命令异常按“问题排查与状态责任”中的矩阵映射为模块结果。
- 稳定验证入口为 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 中的隐藏与并发用例。

### 受限围栏高亮公开入口

入口为 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#highlightRestrictedZone`。

- 公开签名为 `highlightRestrictedZone(id: string): Promise<HarborZoneResult>`。
- 当前实现直接调用 `setZonesVisible(true)`，因此复用围栏获取、标准化、地图替换、状态事件和最新请求淘汰语义。
- 当前实现参数名为 `_id`，不会使用传入 `id` 选择单个围栏，也不会向 service、adapter 或共享地图传递该标识。
- 新增组件测试以一个有效围栏响应调用该方法，并约定返回 `{ status: 'success', count: 1 }`；该测试不证明按 `id` 定点筛选或独立高亮样式。

### 围栏数据标准化

入口为 `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。

- 输入是 `HarborZoneDto`；仅 `enabled === '0'` 且去除空白后 `zone_id` 非空的数据继续转换。
- `points` 按 `_` 拆分点，再按 `,` 转为数值坐标；只保留恰含两个有限数值的坐标。
- 少于三个有效坐标时返回 `null`，否则生成 `{ id: dto.zone_id, coordinates }` 的 `MapZoneModel`。
- `setZonesVisible(true)` 过滤所有 `null` 后再调用共享地图；转换后集合为空时不会执行 `replaceZones()`。

### 最新请求生效

入口为 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。

- 模块以单个递增的 `requestVersion` 覆盖显隐命令和 `highlightRestrictedZone()` 间接发起的显示命令。
- 获取数据后、地图命令完成后以及显示流程捕获异常时，旧版本调用返回 `{ status: 'superseded' }`，不提交成功或错误事件。
- 隐藏流程在 `clearZones()` 完成后检查版本；过期的成功清理返回 `superseded`。
- 组件测试通过两个未决显示请求约定只有最新响应进入 `replaceZones()`，旧请求返回 `superseded`。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`（可选） | `12` | 作为 `initial-zoom` 传给内部 `MapCanvas` |

### Emits

| 事件 | 载荷 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 地图替换成功、清理成功或已映射为错误的流程结果；`empty`、`superseded` 和地图引用缺失分支不触发该事件 |

### Slots

| 名称 | 语义 |
| --- | --- |
| `toolbar` | 渲染在地图画布之前的命名工具栏插槽 |

### Expose

| 方法 | 返回值 | 当前语义 |
| --- | --- | --- |
| `setZonesVisible(visible: boolean)` | `Promise<HarborZoneResult>` | 显示时获取并替换有效围栏，隐藏时清除围栏 |
| `highlightRestrictedZone(id: string)` | `Promise<HarborZoneResult>` | 当前委托给 `setZonesVisible(true)`；`id` 不参与筛选，结果与事件沿用显示流程 |

`HarborZoneResult` 的公开结果集合为：

```ts
{ status: 'success'; count: number }
| { status: 'empty' }
| { status: 'request-error' }
| { status: 'render-error' }
| { status: 'superseded' }
```

## 直接公共依赖

| Provider | 使用的公开契约 | HarborMap 内吸收位置 |
| --- | --- | --- |
| `packages/shared-ui/src/map-canvas/public.ts#MapCanvasExpose` | `replaceZones(zones)` 返回 `success`、`empty` 或 `render-error`；`clearZones()` 返回 `Promise<void>` | `HarborMap.vue#setZonesVisible` |
| `packages/shared-ui/src/map-canvas/public.ts#MapZoneModel` | `{ id: string, coordinates: Array<[number, number]> }` | `normalize-zone.ts#normalizeZone` |

HarborMap 只依赖这些公开声明；共享地图如何绘制、清理或计算数量不属于本模块事实。

## 数据转换与责任分层

| 层级 | 输入 | 语义变化 | 输出 |
| --- | --- | --- | --- |
| Service | 无参数 | 获取港区围栏响应 | `HarborApiResponse { code, data }` |
| Adapter | `HarborZoneDto` | 过滤非目标状态、空标识和无效多边形坐标 | `MapZoneModel \| null` |
| Component | 标准化结果集合 | 过滤 `null`、处理空集合、并发版本和错误映射 | `HarborZoneResult` 与可选状态事件 |
| Shared map | `MapZoneModel[]` 或清理命令 | 执行地图替换或清理 | `MapZoneCommandResult` 或完成信号 |

## 问题排查与状态责任

| 可见结果或症状 | 模块内第一检查点 | 当前责任映射 | 下一验证入口 |
| --- | --- | --- | --- |
| `render-error` 且无状态事件 | `mapCanvasRef.value` | 地图 Expose 尚不可用时直接返回 | 组件挂载与 `MapCanvas` expose 契约 |
| `request-error` | `fetchHarborZones()`、响应 `code`，或显示流程捕获的异常 | 非 200 响应与显示流程异常统一映射为请求错误 | service 替身响应与组件显示用例 |
| `empty` | `normalizeZone()` 的状态、标识和坐标过滤，或共享地图返回 `empty` | 无有效模型时直接返回；地图返回 `empty` 时同时触发错误事件 | adapter 输入边界与 `replaceZones` 返回值用例 |
| `superseded` | 当前调用捕获的版本与 `requestVersion` | 较新命令已经接管结果提交权 | 组件并发请求用例 |
| 高亮方法未只处理传入标识 | `highlightRestrictedZone(_id)` | 当前参数未参与筛选，方法委托显示全部有效围栏 | 新增公开方法用例，并在需要定点语义时增加 id 传播断言 |

显示流程中 `replaceZones()` 抛出的异常会落入统一 `catch` 并返回 `request-error`；只有共享地图以结构化结果返回非成功状态时，才按 `empty` 或 `render-error` 映射。

## 跨功能风险

- `highlightRestrictedZone()` 的名称和 `id` 参数可能被理解为定点高亮，但当前实现只确保有效围栏进入显示流程；修改该语义时必须同步 Expose 类型、组件编排和验证范围。
- 所有公开命令共享同一个 `requestVersion`。新增异步命令时会与现有显隐及高亮入口互相淘汰，必须明确是否继续共享“最新请求生效”策略。
- 显示流程的统一 `catch` 同时覆盖数据获取、标准化和地图调用抛错，返回值本身不能区分这些抛错来源。
- `empty` 的事件语义取决于产生位置：标准化后为空不触发事件，共享地图结构化返回 `empty` 时触发 `error`。

## 删除与保留边界

`highlightRestrictedZone` 是可独立移除的公开入口。删除时需要同步移除：

- `apps/harbor-system/src/components/harbor-map/HarborMap.vue#highlightRestrictedZone` 及 `defineExpose` 项；
- `apps/harbor-system/src/components/harbor-map/types.ts#HarborMapExpose` 中对应签名；
- `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 中对应公开契约用例；
- 本文档的功能索引、Expose 契约、风险与诊断引用。

电子围栏显隐、数据标准化、共享地图依赖和最新请求淘汰是该入口当前复用的既有能力，不因移除高亮入口而一并删除。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件显隐 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 隐藏不请求 service、调用清理并返回成功；事件载荷符合用例预期 | 共享地图真实绘制、service 真实网络行为 | 修改共享地图实现或 service 传输层 |
| 并发淘汰 | 同上 | 组件 | 两个显示请求竞争时仅最新数据进入 `replaceZones()`，旧请求结果为 `superseded` | 所有显隐交错和异常竞态 | 修改 `requestVersion`、增加新异步公开命令 |
| Vue 公开契约 | 同上 | 组件 | `initialZoom` 传入、`toolbar` 可渲染、Expose 方法可访问、隐藏成功触发 `hidden` | Prop 默认值在所有渲染环境中的表现、事件的所有错误分支 | 修改 Props、Emits、Slots 或 Expose |
| 受限围栏高亮入口 | 同上新增的公开方法用例 | 组件 | 方法可通过 Expose 调用，并在一个有效围栏响应下约定成功计数 | 按 `id` 筛选、单独高亮样式、参数向下游传播 | 实现定点选择、样式状态或新的地图高亮契约 |
| Adapter | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` | 代码入口 | 可定位状态、标识和坐标转换规则 | fixture 中没有独立 adapter 测试，不能由组件用例证明全部边界组合 | 修改 DTO、坐标语法或过滤规则时增加单元验证 |

这些入口描述稳定覆盖范围，不代表某次执行结果。

## 文档维护信息

- 规范版本：`ai-module-spec v3`。
- 事实范围：HarborMap 的生产代码、模块内部测试及其实际使用的共享地图公开声明。
- 规范文档落点：`apps/harbor-system/claudedocs/modules/HarborMap.md`。
- 当 Props、Emits、Slots、Expose、结果联合类型、围栏转换规则、共享地图公开契约或并发淘汰语义变化时更新本文档。
