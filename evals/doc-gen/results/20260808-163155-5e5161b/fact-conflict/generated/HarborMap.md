---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 提供港区电子围栏的查询、转换、地图渲染与并发结果淘汰，并通过 Vue 公开契约控制显隐。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  request_supersession:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 并发请求结果淘汰

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-09"
last_updated_by: doc-gen
---

# HarborMap - 港区电子围栏地图组件

## 模块概述

HarborMap 组合围栏查询、DTO 规范化和共享地图画布命令，将显示请求映射为稳定结果与 `zoneStatusChange` 事件。组件使用请求版本号淘汰过期的异步结果。隐藏流程的测试预期与生产实现存在未解决冲突，相关行为仅在“模块内事实冲突”中记录。

## 模块边界

| 路径 | 角色 | 边界事实 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 主入口，持有显隐编排、请求版本和地图画布引用。 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 定义围栏 DTO、公开结果联合类型和 expose 接口。 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 将港区围栏 DTO 转换为地图围栏模型。 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 提供模块专属围栏查询入口和响应类型。 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块内部组件验证入口。 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 提供模块实际使用的地图围栏模型和画布命令公开类型。 |

## 功能目录

### 电子围栏显隐编排

- 入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。
- 显示请求调用 `fetchHarborZones()`；非 `200` 响应映射为 `request-error` 并发出 `zoneStatusChange: error`。
- 有效响应经 `normalizeZone()` 转换并过滤；没有有效围栏时返回 `empty`。
- 有效围栏交给 `MapCanvasExpose.replaceZones()`；成功时发出 `visible` 并返回带数量的 `success`，地图返回的 `empty` 或渲染错误分别映射为 `empty` 或 `render-error`。
- 地图画布引用不存在时返回 `render-error`。
- 隐藏请求的查询顺序存在模块内事实冲突，不在此处固化为确定行为。
- 验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。

### 围栏数据规范化

- 入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。
- 只接收 `enabled === '0'` 且 `zone_id` 非空的 DTO。
- `points` 按下划线分隔点、按逗号分隔坐标，并丢弃非二元或非有限数值坐标。
- 少于三个有效坐标时返回 `null`；否则输出 `{ id, coordinates }` 形式的 `MapZoneModel`。
- 规范化结果由 `setZonesVisible()` 过滤 `null` 后交给共享地图画布。
- 模块边界内没有独立 adapter 测试；组件测试包含有效 DTO 进入显示链路的预期覆盖。

### 并发请求结果淘汰

- 入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。
- 每次调用递增模块内 `requestVersion`，当前调用保存自己的版本号。
- 异步查询完成、地图替换完成或查询异常进入处理时，版本已过期的调用返回 `superseded`。
- 过期的显示查询不会继续提交地图替换；组件测试以两个并发显示请求覆盖“仅最新请求提交结果”的预期。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 传给地图画布的初始缩放值。 |

### Emits

| 名称 | 参数 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 通知围栏已显示、已隐藏或处理失败；隐藏事件的触发前置流程存在事实冲突。 |

### Slots

| 名称 | Slot props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 在地图画布之前插入围栏工具栏内容。 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

隐藏调用的稳定执行顺序尚未确认；调用方不能从公开结果推断是否发生过围栏查询。

## 直接公共依赖

`HarborMap.vue` 和 `normalize-zone.ts` 直接使用 `packages/shared-ui/src/map-canvas/public.ts` 的最小公开契约：

| Provider symbol | 模块内使用位置 | 实际使用的契约 |
| --- | --- | --- |
| `MapZoneModel` | `normalizeZone()` | 输出 `id` 和二维坐标数组。 |
| `MapCanvasExpose.replaceZones` | `setZonesVisible(true)` | 接收规范化围栏数组，返回 `success`、`empty` 或 `render-error`。 |
| `MapCanvasExpose.clearZones` | `setZonesVisible(false)` 的生产实现分支 | 返回 `Promise<void>`；其与查询调用的顺序存在事实冲突。 |

模块不拥有共享地图画布的内部渲染实现。

## 数据转换与责任分层

1. `fetchHarborZones()` 返回 `{ code, data: HarborZoneDto[] }`。
2. `setZonesVisible()` 负责响应码判断、并发版本检查和结果状态映射。
3. `normalizeZone()` 负责启用标记、标识和坐标合法性转换，产出 `MapZoneModel | null`。
4. `setZonesVisible()` 过滤无效结果，并将有效模型数组提交给 `MapCanvasExpose.replaceZones()`。
5. 地图命令结果被吸收为 `HarborZoneResult`，成功或错误路径按实现发出对应事件。

## 模块内事实冲突

| 来源 | 关于 `setZonesVisible(false)` 的事实 | 冲突 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` | `visible === false` 时进入隐藏分支，直接调用 `clearZones()`，该分支没有调用 `fetchHarborZones()`。 | 与模块测试的新预期不一致。 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`（给定 diff 后） | 测试名称和断言期望隐藏前刷新围栏，并期望 `fetchHarborZones()` 被调用一次，同时仍期望清除围栏并返回 `{ status: 'success', count: 0 }`。 | 与当前生产实现不一致。 |

待确认：隐藏契约究竟应在清除前查询一次，还是模块测试预期需要与生产实现重新对齐。冲突解决前，不把“隐藏前刷新”或“隐藏时不查询”写成稳定公开行为。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| 组件契约、显隐编排、围栏规范化、并发淘汰 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 隐藏流程的预期调用、公开 Props/Slot/Expose、事件预期、有效 DTO 的显示链路，以及并发显示请求只提交最新结果的预期覆盖范围。 | 不能单独证明生产实现符合与之冲突的隐藏预期；不能界定所有无效 DTO 组合；不能证明共享地图画布的真实渲染效果。 | 修改 adapter、service 响应语义或共享地图公开契约时增加对应单元或跨 owner 检查。 | Vitest、Vue Test Utils，并以 stub 提供 `MapCanvasExpose`。 |
| 共享地图命令契约 | `packages/shared-ui/src/map-canvas/public.ts` | 类型、跨 owner | 可核对模块使用的 `MapZoneModel`、`replaceZones()` 和 `clearZones()` 公开签名。 | 不覆盖 provider 内部渲染、性能或地图运行时行为。 | 共享公开类型或命令结果联合类型变化时扩大到 shared-ui owner 的验证入口。 | provider 继续从该公开声明暴露这些 symbol。 |

## 文档维护信息

- 文档 owner：`apps/harbor-system`。
- 模块主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`。
- 维护时只纳入模块拥有文件及实际使用的直接公共依赖，不向调用方向扩展边界。
- 事实冲突解决后，同时核对显隐功能目录、公开事件语义、直接公共依赖和组件测试证明范围。
