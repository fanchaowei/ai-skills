---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 通过公开显隐命令编排港区围栏获取、模型转换与地图画布更新，并返回结构化结果。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 围栏显隐编排

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港区围栏地图组件

## 模块概述

HarborMap 封装港区围栏的显隐命令。组件负责获取围栏 DTO、转换为地图画布模型、调用画布公开命令，并通过返回值与事件公开处理结果。

## 模块边界

模块拥有以下实现与验证入口：

- `apps/harbor-system/src/components/harbor-map/HarborMap.vue`：组件入口、显隐编排、并发版本控制和公开契约。
- `apps/harbor-system/src/components/harbor-map/types.ts`：围栏 DTO、命令结果和 Expose 类型。
- `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts`：DTO 到地图围栏模型的转换与无效数据过滤。
- `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts`：港区围栏查询入口与响应类型。
- `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`：组件公开命令的稳定验证入口。

`packages/shared-ui/src/map-canvas/public.ts` 是直接公共依赖的声明，不归 HarborMap 所有。

## 功能目录

### 围栏显隐编排

入口为 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。

显示分支的最小事实链为：

1. `setZonesVisible(true)` 增加 `requestVersion` 并读取 `MapCanvasExpose`。
2. `fetchHarborZones()` 返回围栏响应；非 `200` 响应映射为 `request-error`。
3. `normalizeZone()` 将启用值为 `'0'`、标识非空且至少含三个有效坐标点的 DTO 转换为 `MapZoneModel`，其余项返回 `null` 并被过滤。
4. 无有效围栏时返回 `empty`；否则调用 `replaceZones()`。
5. 画布成功结果映射为 `{ status: 'success', count }` 并发出 `zoneStatusChange: 'visible'`；其他画布结果映射为 `empty` 或 `render-error`。
6. 异步阶段通过版本号识别已被后续命令取代的结果，并返回 `superseded`。

隐藏分支是否请求围栏存在模块内事实冲突，见“模块内事实冲突”，冲突解决前不把其中任一行为写成确定契约。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`（可选） | `12` | 传给地图画布的初始缩放级别。 |

### Emits

| 名称 | 载荷 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 通知围栏进入可见、隐藏或错误状态。 |

### Slots

| 名称 | 作用域参数 | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 在地图画布之前插入工具栏内容。 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 可能为：

- `{ status: 'success'; count: number }`
- `{ status: 'empty' }`
- `{ status: 'request-error' }`
- `{ status: 'render-error' }`
- `{ status: 'superseded' }`

## 直接公共依赖

### `@shared/ui/map-canvas`

HarborMap 使用地图画布组件，并通过 `MapCanvasExpose` 调用以下最小公开契约：

- `replaceZones(zones: MapZoneModel[]): Promise<MapZoneCommandResult>`
- `clearZones(): Promise<void>`

传入的 `MapZoneModel` 包含字符串 `id` 与 `[number, number]` 坐标数组。HarborMap 只吸收 `success`、`empty`、`render-error` 三类画布命令结果。

## 数据转换与责任分层

| 层级 | 入口 | 责任 | 公开结果 |
| --- | --- | --- | --- |
| 查询 | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones` | 提供 `{ code, data }` 形式的港区围栏响应 | `HarborApiResponse` |
| 适配 | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` | 过滤不可渲染 DTO，并把下划线分隔的点串转换为坐标数组 | `MapZoneModel \| null` |
| 编排 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` | 处理请求码、空结果、并发淘汰、画布命令和事件映射 | `HarborZoneResult` 与 `zoneStatusChange` |
| 渲染依赖 | `packages/shared-ui/src/map-canvas/public.ts#MapCanvasExpose` | 替换或清除地图围栏 | `MapZoneCommandResult` 或完成信号 |

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件显隐命令 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | 公开命令在模拟查询与画布依赖下的预期调用顺序、返回结果和交互边界 | 真实后端响应、真实地图渲染效果及跨 owner 集成行为 | 查询响应契约或 `MapCanvasExpose` 变化时增加对应 owner 的契约与集成检查 |

## 模块内事实冲突

### 隐藏前是否刷新围栏

| 来源 | 当前证据 |
| --- | --- |
| 生产实现 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` | `visible` 为 `false` 时直接调用 `clearZones()`；该分支在 `fetchHarborZones()` 之前返回。 |
| 变化集 `changes/fact-conflict.diff` 中的模块测试期望 | 测试名称改为“refreshes zones before hiding”，显式断言隐藏命令调用 `fetchHarborZones()` 一次，并保留 `clearZones()` 调用一次的断言；该 diff 没有新增两次调用的先后顺序断言。 |

两者对隐藏分支是否请求围栏描述不一致。需要确认应修改生产实现以匹配新测试期望，还是修正测试期望以保持直接清除语义；确认前不把“隐藏时请求”或“隐藏不请求”写成稳定公开行为。

## 文档维护信息

- 维护入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`
- 公开类型入口：`apps/harbor-system/src/components/harbor-map/types.ts#HarborMapExpose`
- 直接依赖声明：`packages/shared-ui/src/map-canvas/public.ts#MapCanvasExpose`
- 文档格式：`ai-module-spec v3`
