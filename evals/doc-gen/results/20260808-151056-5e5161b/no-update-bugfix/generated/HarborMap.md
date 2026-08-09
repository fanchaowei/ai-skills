---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: complex
summary: "HarborMap 负责港区电子围栏的查询、规范化、地图显隐编排与过期请求淘汰。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  request_supersession:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 请求淘汰与状态发布

detail_sections:
  scope: 模块边界
  contract: Vue 公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  diagnostics: 问题排查与状态语义
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港区电子围栏组件

## 模块概述

HarborMap 通过公开方法控制港区电子围栏显隐：显示时查询并规范化围栏数据，再交给地图画布替换；隐藏时直接清空地图围栏。模块使用请求版本号阻止较旧的异步结果覆盖较新的操作，并通过返回状态和组件事件向外公开结果。

## 模块边界

| 路径 | 角色 | 模块内职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 公开契约、显隐编排、请求淘汰和状态发布 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 暴露方法及其结果联合类型 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 围栏查询入口及响应类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | DTO 到地图围栏模型的规范化 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 组件契约、隐藏分支和并发淘汰的稳定验证入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 地图围栏模型和地图命令公开契约 |

`apps/harbor-system/src/pages/HarborPage.vue` 是 HarborMap 的调用方，不属于模块边界；本文档不记录其实现、状态或回退逻辑。

## 功能目录

### 电子围栏显隐编排

入口为 `HarborMap.vue#setZonesVisible`。

- `visible: false` 时不查询围栏，调用 `MapCanvasExpose.clearZones()`；有效的最新调用成功后触发 `zoneStatusChange('hidden')`，返回 `{ status: 'success', count: 0 }`。
- `visible: true` 时调用 `fetchHarborZones()`；只有响应 `code === 200` 才进入规范化和地图替换。
- 有效围栏交给 `MapCanvasExpose.replaceZones()`；成功后触发 `zoneStatusChange('visible')`，并返回地图命令提供的数量。
- 地图实例尚不可用时返回 `render-error`，不会发起查询或地图命令。

### 围栏数据规范化

入口为 `normalize-zone.ts#normalizeZone`。

- 只接受 `enabled === '0'` 且去除首尾空白后非空的 `zone_id`。
- `points` 使用下划线分隔点、逗号分隔坐标，并将坐标转换为有限数字。
- 少于三个有效坐标点时返回 `null`；有效结果映射为 `{ id, coordinates }` 的 `MapZoneModel`。
- 显示编排会过滤所有 `null`；没有可用围栏时返回 `empty`，不调用 `replaceZones()`。

### 请求淘汰与状态发布

入口为 `HarborMap.vue#setZonesVisible`。

- 每次调用递增 `requestVersion`，当前调用保存自己的版本号。
- 异步清空、查询或替换结束后，旧版本结果返回 `{ status: 'superseded' }`，不发布旧操作的状态事件。
- 最新的显示成功发布 `visible`，最新的隐藏成功发布 `hidden`；请求或渲染失败按状态责任发布 `error`。
- `superseded` 是 `HarborZoneResult` 的既有公开结果，用于表示结果已被后续调用淘汰。

## Vue 公开契约

### Props

| 名称 | 类型 | 必填 | 默认值 | 语义 |
| --- | --- | --- | --- | --- |
| `initialZoom` | `number` | 否 | `12` | 传递给地图画布的初始缩放级别 |

### Emits

| 事件 | 载荷 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 最新操作完成可见、隐藏或进入需要发布的错误状态 |

### Slots

| 名称 | Slot Props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 在地图画布之前放置围栏工具栏内容 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 的稳定结果为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 直接公共依赖

HarborMap 真实使用 `packages/shared-ui/src/map-canvas/public.ts` 中的最小公开契约：

- `MapCanvasExpose.clearZones(): Promise<void>`：隐藏时清空围栏。
- `MapCanvasExpose.replaceZones(zones: MapZoneModel[]): Promise<MapZoneCommandResult>`：显示时替换围栏，并提供 `success`、`empty` 或 `render-error` 结果。
- `MapZoneModel`：规范化结果包含字符串 `id` 和二维数值坐标数组 `coordinates`。

本文档不复制地图画布 provider 的内部实现。

## 数据转换与责任分层

```text
fetchHarborZones()
  -> HarborApiResponse.data: HarborZoneDto[]
  -> normalizeZone(dto): MapZoneModel | null
  -> 过滤 null
  -> MapCanvasExpose.replaceZones(MapZoneModel[])
  -> HarborZoneResult 与 zoneStatusChange
```

- service 层提供响应码和原始 DTO。
- adapter 层负责字段校验、坐标解析和模型转换。
- 组件层负责编排、过期结果淘汰、地图命令结果映射和事件发布。

## 问题排查与状态语义

| 结果或症状 | 第一检查点 | 模块内语义 | 下一验证入口 |
| --- | --- | --- | --- |
| `empty` | `normalizeZone()` 的过滤结果或 `replaceZones()` 返回值 | 没有有效围栏，或地图命令报告空结果 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` |
| `request-error` | `fetchHarborZones()` 的响应码或异常 | 查询未得到可处理的成功响应 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` |
| `render-error` | `mapCanvasRef`、`clearZones()` 或 `replaceZones()` | 地图画布不可用或地图命令失败 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` |
| `superseded` | `requestVersion` 比较 | 当前结果属于旧调用，不得覆盖较新的操作 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` |
| 收到 `zoneStatusChange('error')` | `setZonesVisible()` 的错误映射分支 | 最新操作发生需要对外发布的请求或渲染错误 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` |

`empty` 的事件语义取决于产生位置：规范化后没有有效围栏时直接返回 `empty`；地图画布返回 `empty` 时组件同时发布 `error`。地图实例尚不可用时直接返回 `render-error`，不发布事件。

## 跨功能风险

- `requestVersion` 检查必须覆盖显示和隐藏链路的成功、失败完成点；遗漏会让旧调用发布错误事件或覆盖新操作结果。
- `HarborZoneResult` 与 `zoneStatusChange` 是两条不同的公开结果通道；修改状态映射时需要同时核对返回值和事件是否仍保持既有语义。
- `normalizeZone()` 的过滤条件直接决定是否调用 `replaceZones()`；DTO 字段或坐标格式变化需要同步核对 adapter、service 类型和组件空结果分支。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件契约与隐藏编排 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | `initialZoom`、`toolbar`、`setZonesVisible`、隐藏时不查询、清空成功和 `hidden` 事件的预期 | 真实地图画布渲染和真实网络行为 | Props、Slots、Expose、Emits 或 MapCanvas 集成方式变化 |
| 并发淘汰 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | 较旧显示请求返回 `superseded` 且不会重复替换围栏的预期 | 隐藏清空失败与后续调用竞态的全部组合 | 修改 `requestVersion` 检查点或新增异步阶段 |
| 数据规范化 | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` | 人工代码核对 | 可核对启用标记、标识和坐标过滤的实现边界 | 不能替代 adapter 单元测试，也不能证明 service 与真实地图画布的集成 | DTO 或 `MapZoneModel` 契约变化时增加 adapter 级验证 |

测试文件只证明稳定预期与覆盖范围，不代表当前实现必然符合预期，也不记录某次执行状态。

## 文档维护信息

- 维护 owner：`apps/harbor-system`
- 主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- 维护时优先核对 `setZonesVisible`、`HarborZoneResult`、`normalizeZone`、`MapCanvasExpose` 和组件测试入口。
- 调用方始终排除；共享地图画布只记录 HarborMap 实际使用的公开契约。
