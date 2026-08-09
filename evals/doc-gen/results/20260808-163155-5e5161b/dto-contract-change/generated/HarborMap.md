---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: "HarborMap 编排电子围栏查询、后端 DTO 归一化、并发结果淘汰与地图画布显隐，并以稳定组件契约返回结构化结果。"

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  harbor_zone_query:
    entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones
    body_section: 围栏查询与响应解包
  dto_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: DTO 归一化
  request_supersession:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 并发结果淘汰

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  diagnostics: 问题排查与症状索引
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-09"
last_updated_by: doc-gen
---

# HarborMap - 电子围栏地图组件

## 模块概述

HarborMap 负责把后端电子围栏响应吸收到组件内部稳定模型：查询层声明 `{ code, data: { items } }` 响应包装，DTO 层声明 `boundary` 字段，adapter 将边界字符串归一化为 `MapZoneModel`，组件再把有效围栏交给共享 `MapCanvas`。组件同时处理显隐命令、请求竞态和对外状态结果；后端字段与响应包装不会穿透到地图画布契约。

## 模块边界

| 路径 | 角色 | 当前职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 公开契约、显隐编排、响应解包、并发淘汰、错误与事件映射 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | `HarborZoneDto`、`HarborZoneResult` 与 `HarborMapExpose` 类型契约 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 围栏查询函数及 `HarborApiResponse` 响应包装契约 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 后端 DTO 到共享地图模型的校验与归一化 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 组件公开契约、隐藏行为和并发请求预期的稳定验证入口 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 模块实际使用的 `MapZoneModel`、`MapCanvasExpose` 与命令结果契约 |

## 功能目录

### 电子围栏显隐编排

`setZonesVisible(visible)` 是显隐命令入口。

- `visible === false` 时不发起围栏请求，直接调用 `MapCanvasExpose.clearZones()`；清除完成且调用仍为最新版本时触发 `zoneStatusChange('hidden')` 并返回 `{ status: 'success', count: 0 }`，已被更新命令淘汰时返回 `superseded`。
- `visible === true` 时依次执行围栏查询、响应解包、DTO 归一化和 `replaceZones()`；渲染成功后触发 `zoneStatusChange('visible')`，并把地图命令返回的数量作为 `{ status: 'success', count }` 返回。
- 地图引用尚未建立时返回 `{ status: 'render-error' }`。

### 围栏查询与响应解包

`fetchHarborZones()` 返回 `Promise<HarborApiResponse>`，当前响应契约为：

```ts
interface HarborApiResponse {
  code: number
  data: { items: HarborZoneDto[] }
}
```

组件只在 `code === 200` 时读取 `response.data.items`。非 200 响应映射为 `request-error` 并触发 `zoneStatusChange('error')`。`data.items` 是后端响应包装变化在组件编排层的吸收位置；下游 adapter 仍逐个接收 `HarborZoneDto`，地图画布不感知该包装。

### DTO 归一化

`HarborZoneDto` 的当前字段为 `zone_id`、`enabled` 和 `boundary`。`normalizeZone(dto)` 在 adapter 边界吸收后端字段语义：

1. 仅处理 `enabled === '0'` 且去除首尾空白后 `zone_id` 非空的 DTO。
2. 从 `boundary` 读取边界字符串，以 `_` 分隔点、以 `,` 分隔坐标，并将坐标转换为数字。
3. 丢弃不是两个有限数字的坐标点；少于三个有效点时返回 `null`。
4. 输出 `{ id: zone_id, coordinates }` 形式的 `MapZoneModel`。

`boundary` 替代旧字段名后的吸收范围止于 DTO 类型与 adapter；`MapZoneModel.coordinates` 和组件公开结果保持稳定。

### 并发结果淘汰

每次调用 `setZonesVisible()` 都递增模块内 `requestVersion`。异步查询返回后、地图替换返回后以及异常捕获时，组件都会比较本次版本与最新版本；旧调用返回 `{ status: 'superseded' }`，且不会继续发出对应的成功或错误事件。该机制保证只有最新显隐命令可以提交可观察结果。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 作为 `initial-zoom` 传给 `MapCanvas` |

### Emits

| 名称 | 参数 | 触发语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏成功显示、成功清除，或请求/渲染处理进入错误映射时触发 |

### Slots

| 名称 | 语义 |
| --- | --- |
| `toolbar` | 渲染在地图画布之前的工具栏内容 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 可能为：

| status | 附加字段 | 当前语义 |
| --- | --- | --- |
| `success` | `count: number` | 清除完成或地图替换完成；清除时数量为 `0` |
| `empty` | 无 | DTO 归一化后没有有效围栏，或地图命令返回 `empty` |
| `request-error` | 无 | 响应码不是 200，或显隐查询流程中的异常被请求错误分支吸收 |
| `render-error` | 无 | 地图引用不存在、清除失败，或地图命令返回非成功且非 `empty` 的结果 |
| `superseded` | 无 | 当前异步调用已被更新的显隐命令淘汰 |

## 直接公共依赖

HarborMap 通过 `@shared/ui/map-canvas` 与 `@shared/ui/map-canvas/public` 使用以下最小公开契约：

- `MapCanvas` 组件接收 `initialZoom` 对应的 `initial-zoom` 属性，并通过模板引用提供地图命令。
- `MapCanvasExpose.replaceZones(zones: MapZoneModel[])` 接收归一化围栏，返回 `success`、`empty` 或 `render-error` 结果。
- `MapCanvasExpose.clearZones()` 清除已渲染围栏。
- `MapZoneModel` 只包含 `id` 与 `Array<[number, number]>` 形式的 `coordinates`。

后端 `boundary` 字段和 `data.items` 响应包装不得直接传入该共享依赖。

## 数据转换与责任分层

```text
fetchHarborZones()
  → HarborApiResponse.data.items
  → HarborZoneDto { zone_id, enabled, boundary }
  → normalizeZone(dto)
  → MapZoneModel { id, coordinates }
  → MapCanvasExpose.replaceZones(zones)
  → HarborZoneResult + zoneStatusChange
```

| 层级 | 模块内吸收责任 | 对下游保持的边界 |
| --- | --- | --- |
| `services/harbor-api.ts` | 声明后端响应由 `data.items` 承载 DTO 数组 | 不在此层解释边界字符串 |
| `types.ts` | 声明后端 DTO 使用 `boundary` 字段 | 不把 DTO 字段暴露为 Vue 组件公开接口 |
| `HarborMap.vue` | 校验响应码并从 `data.items` 解包 DTO 列表 | adapter 仍接收单个 DTO；共享地图不感知响应包装 |
| `adapters/normalize-zone.ts` | 读取 `boundary`，校验并转换坐标 | 输出稳定的 `MapZoneModel` |
| `MapCanvas` 公开契约 | 接收地图模型并返回渲染命令结果 | 不依赖 Harbor DTO 或 API 响应结构 |

## 状态与错误责任矩阵

| 阶段 | 条件 | 返回结果 | 事件 |
| --- | --- | --- | --- |
| 获取地图引用 | 引用不存在 | `render-error` | 无 |
| 隐藏围栏 | `clearZones()` 完成 | `success`, `count: 0` | `hidden` |
| 隐藏围栏 | 清除完成但调用已过期 | `superseded` | 无 |
| 隐藏围栏 | `clearZones()` 抛出异常 | `render-error` | `error` |
| 查询响应 | 调用已过期 | `superseded` | 无 |
| 查询响应 | `code !== 200` | `request-error` | `error` |
| DTO 归一化 | 无有效围栏 | `empty` | 无 |
| 地图替换 | 调用已过期 | `superseded` | 无 |
| 地图替换 | 返回 `success` | `success`, `count` | `visible` |
| 地图替换 | 返回 `empty` | `empty` | `error` |
| 地图替换 | 返回 `render-error` | `render-error` | `error` |
| 显示流程异常 | 查询、解包、归一化或替换抛出异常，且调用仍是最新版本 | `request-error` | `error` |

## 问题排查与症状索引

| 症状 | 第一检查点 | 稳定结构化信号 | 下一验证入口 |
| --- | --- | --- | --- |
| 有 200 响应但返回 `request-error` | `HarborMap.vue#setZonesVisible` 的 `response.data.items` 解包 | `HarborApiResponse.data.items` 是否存在且为数组 | 检查 `services/harbor-api.ts#HarborApiResponse` 与后端响应声明的一致性 |
| 返回 `empty` 且未调用有效围栏渲染 | `normalize-zone.ts#normalizeZone` | `boundary` 分隔后是否至少有三个有限数值坐标点 | 对照 `types.ts#HarborZoneDto` 与 adapter 输入样例 |
| 返回 `render-error` | 地图引用、`clearZones()` 或 `replaceZones()` 结果分支 | 地图引用是否存在，以及命令结果的 `status` | 检查 `packages/shared-ui/src/map-canvas/public.ts#MapCanvasExpose` |
| 较早请求未产生显示结果 | `requestVersion` 比较点 | 返回 `superseded` | `HarborMap.spec.ts` 的最新请求保留场景 |

第一检查点仅用于定位责任边界，不单独证明根因。

## 跨功能风险

- `HarborApiResponse.data.items`、`HarborZoneDto.boundary` 和 `normalizeZone()` 必须作为同一条契约链保持一致；任一层保留旧数组包装或旧字段名都会在解包或归一化阶段中断显示流程。
- `enabled === '0'` 是 adapter 当前保留围栏的判定条件；后端枚举语义变化会直接影响有效围栏数量。
- `requestVersion` 同时约束查询结果、地图命令结果和异常映射；改变异步边界时必须保留旧调用不提交事件的语义。
- 显示流程共用异常捕获会把 `replaceZones()` 抛出的异常映射为 `request-error`；依赖方应以当前结构化结果为准，不从异常来源推断状态。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| 组件公开契约与隐藏行为 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | `initialZoom`、`toolbar` slot、`setZonesVisible` expose、`zoneStatusChange` 事件，以及隐藏时不查询并调用 `clearZones()` 的预期 | 真实后端响应、真实地图渲染和 adapter 的坐标边界情况 | Vue 公开契约或共享地图命令签名变化 | Vue Test Utils 能挂载组件并提供 MapCanvas stub |
| 并发请求淘汰 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 较新显示请求优先、较旧调用返回 `superseded` 且只提交一次地图替换的预期 | 网络层时序、取消机制或共享地图内部并发行为 | 请求编排、版本判断点或地图替换时机变化 | 查询函数与地图命令可被稳定替换为可控测试替身 |
| DTO 与响应契约 | `apps/harbor-system/src/components/harbor-map/types.ts`、`services/harbor-api.ts`、`adapters/normalize-zone.ts` 与 `HarborMap.vue#setZonesVisible` 的类型及静态契约 | 类型/静态 | `data.items`、`boundary`、解包位置与 `MapZoneModel` 输出之间的声明链 | 后端运行时一定遵守声明，或异常/畸形数据已被集成覆盖 | 后端 DTO、响应包装、adapter 输出或共享地图模型变化 | 相关 TypeScript 声明参与同一应用的类型检查 |

## 模块内事实冲突

生产代码变化后的 DTO 与响应契约使用 `data.items` 和 `boundary`，但 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 的可见请求 fixture 仍构造 `data: HarborZoneDto[]`，并为 DTO 提供 `points`。因此，该测试文件当前记录的可见请求输入预期与生产契约不一致，不能作为新 DTO/响应包装的稳定证明；本文档以生产代码声明记录当前实现事实，同时保留此冲突，未把旧 fixture 补写为当前契约。

## 文档维护信息

- 模块 owner：`apps/harbor-system`
- 主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- DTO 或响应包装变化时，优先核对“围栏查询与响应解包”“DTO 归一化”“数据转换与责任分层”和“验证入口与证明范围”。
- Vue 组件公开契约或共享地图模型变化时，同步核对“当前公开契约”与“直接公共依赖”。
