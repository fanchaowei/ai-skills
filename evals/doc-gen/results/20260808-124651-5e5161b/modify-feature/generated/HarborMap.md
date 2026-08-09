---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: complex-module
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 负责电子围栏数据获取、边界归一化、并发淘汰及地图显隐渲染，并通过组件公开契约返回结构化结果。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏边界归一化

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  diagnostics: 问题排查
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 电子围栏地图模块

## 模块概述

HarborMap 以 `setZonesVisible()` 编排围栏查询、归一化、地图替换或清除，并用请求版本号淘汰过期异步结果。围栏 DTO 到地图模型的转换由专属 adapter 负责；地图绘制通过共享 MapCanvas 的公开契约完成。

## 模块边界

| 路径 | 角色 | 模块内职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 组件公开契约、显隐编排、状态与事件映射、并发淘汰 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 围栏 DTO、公开结果联合类型和 Expose 类型 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 提供 `fetchHarborZones()` 查询入口及响应类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 将围栏 DTO 过滤并转换为地图模型 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 组件契约、显隐编排和并发淘汰的验证入口 |
| `apps/harbor-system/src/components/harbor-map/adapters/__tests__/normalize-zone.spec.ts` | owned | 围栏有效边界点数量规则的验证入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | HarborMap 实际使用的地图模型与命令结果契约 |

调用 HarborMap 的页面、页面状态和失败回退不属于本模块边界。

## 功能目录

### 电子围栏显隐编排

- 入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。
- 显示时调用 `fetchHarborZones()`；响应码不是 `200` 时返回 `request-error` 并发出 `zoneStatusChange('error')`。
- 响应数据逐项交给 `normalizeZone()`，空值被过滤；没有可渲染围栏时返回 `empty`，不调用 `replaceZones()`。
- 存在可渲染围栏时调用 MapCanvas 的 `replaceZones()`；成功时发出 `visible` 并返回实际数量，非成功结果映射为 `empty` 或 `render-error`，同时发出 `error`。
- 隐藏时不请求围栏，直接调用 `clearZones()`；成功时发出 `hidden` 并返回数量为 `0` 的成功结果。
- 每次调用递增 `requestVersion`；已被后续调用替代的异步结果返回 `superseded`，不继续提交对应的可见结果。
- 验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。

### 围栏边界归一化

- 入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。
- 只接受 `enabled === '0'` 且 `zone_id.trim()` 非空的 DTO。
- `points` 以 `_` 分隔点、以 `,` 分隔坐标；只保留恰有两个有限数值的坐标点，并保持原有顺序。
- 当前实现要求至少四个有效边界点；少于四个时返回 `null`。
- 有效输入转换为 `{ id: dto.zone_id, coordinates }`，供 MapCanvas 的 `replaceZones()` 使用。
- 验证入口：`apps/harbor-system/src/components/harbor-map/adapters/__tests__/normalize-zone.spec.ts`。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 传给 MapCanvas 的初始缩放级别 |

### Emits

| 名称 | 参数 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 地图围栏成功显示、成功清除或查询/渲染失败时发出 |

### Slots

| 名称 | Slot Props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 渲染在地图画布之前的围栏工具栏内容 |

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

## 直接公共依赖

`@shared/ui/map-canvas` 是跨 owner 的直接公共依赖。HarborMap 使用的最小契约为：

- `MapZoneModel`：包含 `id: string` 和 `coordinates: Array<[number, number]>`。
- `MapCanvasExpose.replaceZones(zones)`：接收归一化后的地图围栏，返回 `success`、`empty` 或 `render-error` 结果。
- `MapCanvasExpose.clearZones()`：清除当前围栏。

模块只依赖这些公开类型和命令，不拥有 MapCanvas 的内部渲染实现。

## 数据转换与责任分层

1. `fetchHarborZones()` 提供 `{ code, data: HarborZoneDto[] }`。
2. `normalizeZone()` 承担启用标记、标识和坐标合法性过滤，并执行至少四个有效边界点的规则。
3. `HarborMap.vue#setZonesVisible` 过滤 `null`，处理空集合、请求版本和错误结果。
4. MapCanvas 接收 `MapZoneModel[]` 并负责替换或清除地图围栏。
5. HarborMap 将内部阶段结果收敛为 `HarborZoneResult` 和 `zoneStatusChange` 事件。

## 状态与错误责任矩阵

| 场景 | MapCanvas 操作 | 返回结果 | 事件 |
| --- | --- | --- | --- |
| 隐藏且清除成功 | `clearZones()` | `success, count: 0` | `hidden` |
| 隐藏且清除抛错 | `clearZones()` | `render-error` | `error` |
| 查询响应码非 `200` 或查询抛错 | 无替换 | `request-error` | `error` |
| 归一化后没有围栏 | 无替换 | `empty` | 无 |
| 替换成功 | `replaceZones()` | `success, count` | `visible` |
| 替换返回 `empty` | `replaceZones()` | `empty` | `error` |
| 替换返回其他失败或抛错 | `replaceZones()` | `render-error` | `error` |
| 异步结果被新调用取代 | 终止后续结果提交 | `superseded` | 无 |

## 问题排查

| 症状/结构化结果 | 第一检查点 | 下一验证入口 |
| --- | --- | --- |
| `empty` 且未调用地图替换 | 检查 `normalizeZone()` 的启用标记、非空 ID、有限坐标及四点下限 | `adapters/__tests__/normalize-zone.spec.ts` |
| `request-error` | 检查 `fetchHarborZones()` 的响应码或异常边界 | `__tests__/HarborMap.spec.ts` 中的显示编排用例 |
| `render-error` | 检查 MapCanvas 的 `clearZones()` / `replaceZones()` 公开结果或异常 | `__tests__/HarborMap.spec.ts` 的 MapCanvas stub 边界 |
| `superseded` | 检查调用顺序与 `requestVersion` 淘汰点 | `__tests__/HarborMap.spec.ts` 的最新请求用例 |

第一检查点用于缩小模块内故障边界，不单独证明根因。

## 跨功能风险

- 四点下限同时影响归一化与显示编排：上游只有三个有效坐标点的围栏会被过滤；若全部被过滤，组件返回 `empty` 且不会调用 `replaceZones()`。
- 显示、隐藏共享同一 `requestVersion`；修改异步检查位置时，需要保持过期结果不覆盖较新调用。
- `replaceZones()` 返回 `empty` 时组件会发出 `error`，而归一化后为空时不会发出事件；修改空数据语义时需同步核对公开结果和 Emits。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| adapter | `apps/harbor-system/src/components/harbor-map/adapters/__tests__/normalize-zone.spec.ts` | 单元 | 三个有效点被拒绝、四个有效点按顺序转换为地图模型的预期 | 组件异步编排、真实请求和地图渲染 | DTO 解析格式、启用规则或 MapZoneModel 契约变化 |
| 组件契约与编排 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 隐藏不发请求、清除行为、最新请求淘汰旧请求、Props/Emits/Slots/Expose 的预期覆盖 | 真实 API、MapCanvas 内部绘制和跨页面交互 | 公开契约、状态映射、并发策略或共享地图契约变化 |

测试入口描述稳定预期与覆盖范围，不代表实现符合预期或某次执行结果。

## 模块内事实冲突

- `normalizeZone()` 当前实现明确拒绝少于四个有效边界点；`normalize-zone.spec.ts` 也以三点拒绝、四点接受作为预期。
- `HarborMap.spec.ts` 的“仅保留最新显示请求结果”用例仍使用三个有效点的 DTO，并期待 `replaceZones()` 被调用且最新请求返回成功。
- 该组件测试数据经过当前 adapter 会被全部过滤，与其成功预期不一致。在统一测试数据或预期前，该用例的三点成功预期不作为当前围栏规则。

## 文档维护信息

- Owner：`apps/harbor-system`。
- 围栏 DTO、归一化规则、MapCanvas 公开契约、异步淘汰策略或 Vue 公开契约变化时更新本文档。
- `feature_index` 只指向模块拥有的稳定入口；调用方行为不进入本文档。
