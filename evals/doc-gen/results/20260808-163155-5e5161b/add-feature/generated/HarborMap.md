---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 负责港区电子围栏的查询、规范化、地图显隐编排，并通过组件公开契约提供显隐和受限区域高亮入口。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  restricted_zone_highlight:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#highlightRestrictedZone
    body_section: 受限区域高亮入口
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  latest_request_wins:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 并发请求淘汰

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

# HarborMap - 港区地图围栏组件

## 模块概述

`HarborMap` 渲染共享 `MapCanvas`，查询港区围栏数据，将可用 DTO 转换为地图模型，并负责围栏的显示、隐藏、并发淘汰和结果映射。组件同时公开 `setZonesVisible` 与 `highlightRestrictedZone`；后者当前复用显式显示链路，不执行按 `id` 定位或筛选。

## 模块边界

| 角色 | 路径 | 边界事实 |
| --- | --- | --- |
| owned | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 组件公开契约、地图引用、显隐编排、请求版本和结果映射 |
| owned | `apps/harbor-system/src/components/harbor-map/types.ts` | 围栏 DTO、公开结果联合类型和 Expose 接口 |
| owned | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | 港区围栏查询入口及响应类型 |
| owned | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | DTO 到共享地图模型的规范化规则 |
| owned | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 模块公开行为与并发预期的稳定验证入口 |
| direct-public-dependency | `packages/shared-ui/src/map-canvas/public.ts` | 模块实际使用的 `MapCanvasExpose`、`MapZoneModel` 和命令结果契约 |

边界停止于 `HarborMap` 的公开组件契约，不沿调用方向纳入页面状态、回退逻辑或调用方测试。

## 功能目录

### 电子围栏显隐编排

- 真实入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。
- 编排与状态：每次调用递增 `requestVersion`，并读取当前 `mapCanvasRef`；地图引用不存在时返回 `{ status: 'render-error' }`。
- 隐藏链路：`visible === false` 时调用 `MapCanvasExpose.clearZones()`；清空完成且请求版本仍为最新时触发 `zoneStatusChange('hidden')`，返回 `{ status: 'success', count: 0 }`。
- 显示链路：调用 `fetchHarborZones()`，要求响应 `code === 200`，经 `normalizeZone()` 转换并过滤无效项；无可用围栏时返回 `{ status: 'empty' }`，否则调用 `MapCanvasExpose.replaceZones()`。
- 公开结果：地图替换成功时触发 `zoneStatusChange('visible')` 并返回成功数量；请求、转换链路或地图命令按当前分支映射为 `request-error`、`render-error`、`empty` 或 `superseded`。
- 验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 覆盖隐藏时不请求接口、清空地图和隐藏事件预期。

### 受限区域高亮入口

- 真实入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#highlightRestrictedZone`。
- 公开签名：`highlightRestrictedZone(id: string): Promise<HarborZoneResult>`。
- 当前编排：实现参数名为 `_id`，参数值不参与查询、筛选或地图命令；该入口直接返回 `setZonesVisible(true)` 的结果。
- 共享责任：该入口复用围栏查询、规范化、地图替换、`requestVersion` 淘汰、结果联合类型和 `zoneStatusChange` 事件语义。
- 验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 记录通过公开 Expose 调用后返回成功数量的预期；该测试不覆盖按 `id` 定位或仅高亮单个围栏。

### 围栏数据规范化

- 真实入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。
- 输入筛选：仅处理 `enabled === '0'` 且 `zone_id` 去除空白后非空的 `HarborZoneDto`。
- 坐标转换：按 `_` 拆分点、按 `,` 拆分坐标并转为数字，只保留两个有限数值组成的坐标对。
- 公开结果：至少三个有效坐标时返回 `{ id: dto.zone_id, coordinates }` 的 `MapZoneModel`，否则返回 `null`；调用方在交给地图前过滤 `null`。
- 验证入口：组件测试通过围栏响应驱动该转换链路，但当前 fixture 未提供 adapter 独立测试入口。

### 并发请求淘汰

- 真实入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` 中的 `requestVersion`。
- 每次显隐或高亮调用都共享并递增同一个版本号，因此后发调用会使先发调用成为旧版本。
- 版本检查发生在清空完成、查询返回、地图替换返回以及显示链路异常后；旧版本返回 `{ status: 'superseded' }`，不提交对应的成功公开结果。
- 隐藏链路的 `clearZones()` 异常分支不执行版本比较，会触发错误事件并返回 `render-error`。
- 验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 覆盖两个并发显示请求只让最新响应进入 `replaceZones()` 的预期。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 模块内用途 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 作为 `initial-zoom` 传给 `MapCanvas` |

### Emits

| 事件 | 参数 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 地图替换成功、地图清空成功，或请求/地图命令进入错误映射时触发 |

本地规范化后为空、请求被淘汰以及地图引用尚不存在的分支不触发该事件。

### Slots

| 名称 | Slot props | 用途 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图组件之前的工具栏内容 |

### Expose

| 方法 | 返回 | 当前语义 |
| --- | --- | --- |
| `setZonesVisible(visible: boolean)` | `Promise<HarborZoneResult>` | 显示时查询并替换围栏，隐藏时清空围栏 |
| `highlightRestrictedZone(id: string)` | `Promise<HarborZoneResult>` | 当前忽略 `id` 并委托 `setZonesVisible(true)` |

`HarborZoneResult` 为：

```ts
type HarborZoneResult =
  | { status: 'success'; count: number }
  | { status: 'empty' }
  | { status: 'request-error' }
  | { status: 'render-error' }
  | { status: 'superseded' }
```

## 直接公共依赖

| Provider | 使用的公开契约 | HarborMap 的吸收位置 |
| --- | --- | --- |
| `@shared/ui/map-canvas` | 默认导出的 `MapCanvas` 组件 | `HarborMap.vue` 模板通过 `ref` 获取公开命令入口，并传入 `initialZoom` |
| `packages/shared-ui/src/map-canvas/public.ts#MapCanvasExpose` | `replaceZones(zones)`、`clearZones()` | `setZonesVisible` 的地图替换与清空阶段 |
| `packages/shared-ui/src/map-canvas/public.ts#MapZoneModel` | `id`、`coordinates` | `normalizeZone` 的成功输出 |
| `packages/shared-ui/src/map-canvas/public.ts#MapZoneCommandResult` | `success`、`empty`、`render-error` | 地图替换结果到 `HarborZoneResult` 的映射 |

## 数据转换与责任分层

1. `fetchHarborZones()` 返回 `{ code, data: HarborZoneDto[] }`。
2. `setZonesVisible(true)` 先处理响应码和请求版本，再将 `data` 逐项交给 `normalizeZone()`。
3. `normalizeZone()` 负责业务字段筛选、坐标解析和 `HarborZoneDto → MapZoneModel | null` 转换。
4. `HarborMap.vue` 过滤 `null`，处理模块级 `empty`，并把 `MapZoneModel[]` 交给 `MapCanvasExpose.replaceZones()`。
5. `HarborMap.vue` 将共享地图命令结果吸收为 `HarborZoneResult` 和 `zoneStatusChange` 事件。

## 问题排查与状态责任

| 公开结果或信号 | 第一检查点 | 模块内稳定含义 | 下一验证入口 |
| --- | --- | --- | --- |
| `request-error` | `HarborMap.vue#setZonesVisible` 的查询响应码与显示链路异常分支 | 查询响应码不是 `200`，或显示链路在查询、转换、地图替换调用中抛出异常 | `HarborMap.spec.ts` 中对 `fetchHarborZones` 与 `replaceZones` 的受控替换 |
| `render-error` | `mapCanvasRef`、`clearZones()`、`replaceZones()` 的返回分支 | 地图引用不可用、清空抛出异常，或地图替换返回 `render-error` | 使用 `MapCanvasStub` 的组件测试入口 |
| `empty` | `normalizeZone` 后的数组及地图命令结果 | 没有合格围栏，或共享地图返回 `empty` | 围栏响应 fixture 与 `replaceZones` mock 结果 |
| `superseded` | `requestVersion` 比较点 | 当前调用结果已被后发显隐或高亮调用淘汰 | 并发显示请求测试 |
| `zoneStatusChange('error')` | 错误事件触发分支 | 模块已将当前分支映射为公开错误信号；该信号本身不区分请求与渲染来源 | 结合返回的 `HarborZoneResult.status` 检查对应分支 |

## 跨功能风险

- `setZonesVisible` 与 `highlightRestrictedZone` 共享 `requestVersion`；任一入口的后发调用都能淘汰另一入口尚未完成的显示结果。
- `highlightRestrictedZone` 的名称和参数形成按区域高亮入口，但当前实现不消费 `id`，公开效果等同于显示全部规范化后仍有效的围栏。
- 隐藏链路的清空异常不检查是否已被后发调用淘汰，因此该异常仍会产生 `zoneStatusChange('error')` 和 `render-error`。
- `normalizeZone` 将 `enabled === '0'` 作为可渲染条件；该字段语义变化会同时影响显式显示和高亮入口。

## 删除与保留边界

- 受限区域高亮入口具有独立公开表面：`HarborMap.vue#highlightRestrictedZone`、`HarborMapExpose.highlightRestrictedZone` 和对应组件测试共同构成该功能边界。
- 该入口当前没有专属 service、adapter、状态或地图命令；其余显隐、规范化、共享地图依赖和并发淘汰能力属于 `setZonesVisible`，不随高亮公开入口一起归属。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| 组件契约与交互 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | Props 传入、`toolbar` slot、Expose 可调用、隐藏事件、隐藏不请求接口等预期 | 真实浏览器布局、真实地图 SDK 渲染和页面调用方状态 | 模板结构、事件负载、slot 或真实 MapCanvas 集成变化 | Vue Test Utils、Vitest 和 MapCanvas stub 可用 |
| 并发显式显示 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 两个显示请求并发时仅最新响应进入地图替换的预期 | 隐藏与显示交错、清空异常淘汰和真实网络取消 | `requestVersion` 检查点、请求模型或清空流程变化 | 可控制 `fetchHarborZones` Promise 完成顺序 |
| 受限区域高亮公开入口 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | Expose 方法存在并复用显示链路返回成功数量的预期 | `id` 定位、单区视觉样式、多个围栏中的选择语义 | 高亮开始消费 `id`、新增地图高亮命令或专属状态 | `fetchHarborZones` 与 `replaceZones` 可被稳定替换 |
| 共享地图契约 | `packages/shared-ui/src/map-canvas/public.ts` | 类型/契约检查入口 | HarborMap 所引用的地图模型、清空和替换命令签名 | provider 内部渲染行为和运行时兼容性 | `MapCanvasExpose`、`MapZoneModel` 或结果联合类型变化 | 公开声明保持为共享 owner 的稳定契约 |

## 文档维护信息

- 事实入口：`HarborMap.vue`、`types.ts`、`services/harbor-api.ts`、`adapters/normalize-zone.ts`、模块内部测试以及共享地图公开声明。
- 维护触发：Props、Emits、Slots、Expose、`HarborZoneResult`、围栏筛选规则、请求版本语义、共享地图公开契约或上述路径/symbol 变化。
- 边界约束：只维护 HarborMap 拥有的实现和其真实使用的最小共享公开契约，不纳入调用方实现。
