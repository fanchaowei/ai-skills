---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 编排港区电子围栏的查询、规范化、显示、隐藏和并发结果淘汰。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  request_supersession:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#requestVersion
    body_section: 并发请求淘汰

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  data_flow: 数据转换与责任分层
  risks: 跨功能风险

status: active
last_updated: "2026-08-09"
last_updated_by: doc-gen
---

# HarborMap - 港区电子围栏地图组件

## 模块概述

HarborMap 是港口系统内负责电子围栏显隐编排的 Vue 组件。显示时读取 DTO、转换为共享地图模型并替换图层；隐藏时直接清除图层。

## 模块边界

### 模块拥有

| 路径 | 角色 | 职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 契约、显隐编排、结果映射和请求淘汰 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | DTO、返回结果和 expose 类型 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 围栏请求入口与响应类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | DTO 到共享地图模型的转换 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块内组件验证入口 |

### 明确排除

- `apps/harbor-system/src/pages/HarborPage.vue` 是 caller，其状态、回退和测试不属于 HarborMap 当前事实。
- `packages/shared-ui/src/map-canvas/public.ts` 是直接公共依赖，不归 HarborMap 所有。

## 功能目录

### 电子围栏显隐编排

入口为 `HarborMap.vue#setZonesVisible`。隐藏时只调用 `clearZones()`；显示时调用 `fetchHarborZones()`、`normalizeZone()` 和 `replaceZones()`。公开结果包括 `success`、`empty`、`request-error`、`render-error` 和 `superseded`。

### 围栏数据规范化

入口为 `normalize-zone.ts#normalizeZone`。

- 只处理 `enabled === '0'` 且 `zone_id` 非空的 DTO。
- `points` 按 `_` 拆点、按 `,` 拆坐标，并过滤非有限数字。
- 有效坐标少于 4 个时返回 `null`；其余结果转换为 `MapZoneModel`。

### 并发请求淘汰

`setZonesVisible()` 每次调用递增 `requestVersion`。异步结果返回时若版本已过期，返回 `superseded`，不发布过期成功状态。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 |
| --- | --- | --- |
| `initialZoom` | `number?` | `12` |

### Emits

| 名称 | 载荷 |
| --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` |

### Slots

| 名称 | Slot props |
| --- | --- |
| `toolbar` | 无 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

## 直接公共依赖

HarborMap 从 `packages/shared-ui/src/map-canvas/public.ts` 使用 `MapZoneModel`、`MapCanvasExpose.replaceZones()` 和 `MapCanvasExpose.clearZones()` 的最小公开契约，不记录 provider 内部实现。

## 数据转换与责任分层

`HarborZoneDto → fetchHarborZones → normalizeZone → MapZoneModel → MapCanvasExpose → HarborZoneResult`。

- service 负责响应边界；adapter 负责字段和坐标转换；组件负责异步编排和公开结果；共享地图负责渲染。

## 跨功能风险

- `requestVersion` 保证最后调用获胜。
- `empty` 与 `superseded` 只通过 expose 返回值表达，不触发成功事件。
- DTO、共享地图契约或公开结果变化时，需要同时核对数据流、功能章节和验证范围。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- |
| 组件编排与 Vue 契约 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 隐藏不请求、最后调用获胜、Props/Emits/Slots/Expose 预期 | 真实地图渲染和页面调用方状态 | 修改 shared-ui 契约或页面集成 |
| DTO 转换 | `apps/harbor-system/src/components/harbor-map/adapters/__tests__/normalize-zone.spec.ts` | 三个有效边界点被拒绝、四个有效边界点转换为 `MapZoneModel` 的预期 | 启用值、空 ID、非有限坐标过滤、服务端数据质量和地图投影 | 修改 DTO、其他规范化分支或 `MapZoneModel` |

### 模块内事实冲突

- `normalize-zone.ts#normalizeZone` 与 `adapters/__tests__/normalize-zone.spec.ts` 将四个有效坐标定义为最低规范化条件；`HarborMap.spec.ts` 的并发请求用例仍以三个坐标点构造可渲染围栏，并期待成功结果与一次 `replaceZones()` 调用。该验证夹具与当前规范化前置条件冲突，因此组件测试入口对“最后调用获胜的成功渲染路径”的证明范围受此冲突限制。

## 文档维护信息

- 更新时继续排除 caller，只记录真实使用的直接公共依赖。
- 路径、symbol、公开契约、稳定状态或验证入口变化时更新对应索引和正文。
