---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 负责港区电子围栏的查询、标准化、地图显隐编排、并发结果淘汰与状态结果输出。

feature_index:
  - entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  - entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据标准化
  - entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 最新请求结果生效

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  diagnostics: 问题排查与症状索引
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港区围栏地图组件

## 模块概述

HarborMap 对外提供电子围栏显隐命令。显示链路查询港区围栏 DTO，将有效数据转换成地图围栏模型，再委托共享 `MapCanvas` 替换渲染；隐藏链路直接清除地图围栏。模块以结构化返回值、`zoneStatusChange` 事件和请求版本淘汰表达结果。

## 模块边界

| 角色 | 路径 | 模块内责任 |
| --- | --- | --- |
| owned | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | Vue 公开契约、显隐编排、结果映射、事件发出和并发淘汰 |
| owned | `apps/harbor-system/src/components/harbor-map/types.ts` | 港区围栏 DTO、公开命令结果与 Expose 类型 |
| owned | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | 港区围栏查询入口与响应结构 |
| owned | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | DTO 到地图围栏模型的专属转换与无效数据过滤 |
| owned | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 模块公开行为与编排预期的稳定组件测试入口 |
| direct-public-dependency | `packages/shared-ui/src/map-canvas/public.ts` | HarborMap 实际使用的地图围栏模型及显隐命令结果契约 |

模块不拥有外部页面或其他调用方的控件状态、失败回退和交互实现。实际地图绘制过程属于 `MapCanvas`；HarborMap 只拥有调用、结果解释以及自身公开信号的一致性。

## 功能目录

### 电子围栏显隐编排

入口为 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。

- `setZonesVisible(false)` 调用 `MapCanvasExpose.clearZones()`；当前请求仍为最新时发出 `hidden` 并返回 `{ status: 'success', count: 0 }`。
- `setZonesVisible(true)` 调用 `fetchHarborZones()`，仅在响应 `code === 200` 时继续；非 200 响应映射为 `request-error`。
- 查询数据经 `normalizeZone()` 转换并过滤；没有可渲染围栏时返回 `empty`。
- 非空围栏交给 `MapCanvasExpose.replaceZones()`；共享组件的结果再映射为 `HarborZoneResult` 和模块事件。
- 地图引用不存在时直接返回 `render-error`。

最短事实链：`setZonesVisible` → `fetchHarborZones` / `clearZones` → `normalizeZone` → `replaceZones` → `HarborZoneResult` 与 `zoneStatusChange` → `HarborMap.spec.ts`。

### 围栏数据标准化

入口为 `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`。

- 仅 `enabled === '0'` 且 `zone_id` 非空的 DTO 进入坐标转换。
- `points` 以 `_` 拆分点、以 `,` 拆分数值，并过滤非二元或非有限数值坐标。
- 少于三个有效坐标时返回 `null`；有效输入转换为 `{ id, coordinates }` 的 `MapZoneModel`。
- `setZonesVisible(true)` 过滤所有 `null`；过滤后的空集合在进入共享渲染边界前映射为 `empty`。

最短事实链：`HarborZoneDto` → `normalizeZone` → `MapZoneModel | null` → 非空 `MapZoneModel[]` → `replaceZones` → `HarborMap.spec.ts`。

### 最新请求结果生效

入口为 `apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`。

- 每次命令递增模块内 `requestVersion`，并捕获本次 `currentVersion`。
- 查询完成和渲染完成后均比较版本；过期命令返回 `superseded`。
- 过期的显示请求不会继续进入后续转换或公开成功结果；模块测试覆盖两个并发显示请求仅由最新请求进入 `replaceZones()` 的预期。

最短事实链：`setZonesVisible` → `requestVersion` → 异步阶段后的版本比较 → `superseded` 或最新请求结果 → `HarborMap.spec.ts`。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number?` | `12` | 传给 `MapCanvas` 的初始缩放级别 |

### Emits

| 名称 | 载荷 | 语义 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 报告围栏可见、已隐藏或命令错误；`visible` 与渲染完成的时序存在输入变化集所揭示的事实冲突，见“模块内事实冲突” |

### Slots

| 名称 | 语义 |
| --- | --- |
| `toolbar` | 在地图画布前渲染围栏工具区内容 |

### Expose

```ts
interface HarborMapExpose {
  setZonesVisible(visible: boolean): Promise<HarborZoneResult>
}
```

`HarborZoneResult` 的稳定结构化状态为 `success`、`empty`、`request-error`、`render-error` 或 `superseded`；只有 `success` 携带 `count`。

## 直接公共依赖

HarborMap 通过 `@shared/ui/map-canvas/public` 使用以下最小公开契约：

- `MapZoneModel`：`{ id: string; coordinates: Array<[number, number]> }`，是 `normalizeZone()` 的有效输出。
- `MapCanvasExpose.replaceZones(zones)`：返回 `success`、`empty` 或 `render-error` 的结构化结果。
- `MapCanvasExpose.clearZones()`：返回 `Promise<void>`；异常由 HarborMap 映射为自身错误结果与事件。

HarborMap 不拥有 `MapCanvas` 的绘制实现；是否完成实际渲染以 `replaceZones()` 返回的 `MapZoneCommandResult` 为直接边界信号。

## 数据转换与责任分层

```text
HarborApiResponse
  → HarborZoneDto[]
  → normalizeZone()
  → MapZoneModel[]
  → MapCanvasExpose.replaceZones()
  → MapZoneCommandResult
  → HarborZoneResult + zoneStatusChange
```

| 层级 | 拥有的判断 | 不拥有的判断 |
| --- | --- | --- |
| 查询层 | HTTP 风格响应结构和 `code` | 地图是否完成绘制 |
| 转换层 | 启用标志、ID、坐标有效性和最少点数 | 画布如何解释坐标 |
| 共享渲染边界 | `replaceZones()` 的 `success` / `empty` / `render-error` 结果 | HarborMap 对外发出哪个事件 |
| HarborMap 编排层 | 结果映射、事件时序、请求淘汰和 Expose 返回值 | 外部调用方如何保存 UI 状态 |

## 问题排查与症状索引

### 症状：围栏渲染失败，但外部界面仍呈现已开启

- **第一检查点**：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` 中 `await mapCanvas.replaceZones(zones)` 前后。检查 `visible` 是否在 `replaceZones()` 成功返回前发出，以及 `result.status === 'render-error'` 分支是否仍发出 `error`。这是首个可观察分叉点，不等同于已经确认根因。
- **稳定信号**：优先读取 `MapCanvasExpose.replaceZones()` 的结构化结果和 `setZonesVisible()` 返回的 `HarborZoneResult`。若两者均为 `render-error`，同时出现 `zoneStatusChange('visible')`，则形成“渲染结果失败、模块状态事件成功”的稳定矛盾信号；此时不能单独把 `visible` 事件当作渲染成功证明。
- **故障边界**：`replaceZones()` 未被调用时，检查查询响应、转换过滤或地图引用；`replaceZones()` 返回 `render-error` 时，实际绘制失败位于共享渲染边界，而 HarborMap 是否错误发出 `visible`、是否遗漏 `error` 属于 HarborMap 的结果映射与事件时序边界。外部控件如何消费信号不属于本模块。
- **下一验证入口**：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。将 `replaceZones` 定向为 `{ status: 'render-error' }`，同时观察公开方法返回 `{ status: 'render-error' }`、事件中不出现 `visible` 且出现 `error`。现有测试文件覆盖隐藏、最新请求获胜和 Props/Emits/Slots/Expose，但没有覆盖该渲染失败分支。

## 模块内事实冲突

- 当前仓库中的 `HarborMap.vue` 在 `replaceZones()` 成功后才发出 `visible`，并在非成功结果上发出 `error`。
- 输入变化集 `changes/ui-state-symptom.diff` 的变更后代码把 `visible` 移到 `replaceZones()` 之前，并让 `render-error` 分支只返回结果而不发出 `error`。
- 用户描述的症状与输入变化集的变更后行为一致。变化集处置完成前，`zoneStatusChange` 的渲染完成语义不能作为单一稳定事实；结构化返回值仍是排查入口。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件公开契约与隐藏链路 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | Props、`toolbar` slot、Expose 可达，以及隐藏命令不查询并发出 `hidden` 的预期 | 真实地图绘制成功或外部 UI 状态 | 修改 `MapCanvas` 公开契约或外部交互时扩大到对应 owner |
| 并发显示链路 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件测试 | 两个并发显示请求仅由最新请求进入渲染的预期 | 所有显示错误分支和真实网络时序 | 修改请求版本策略或增加取消机制时增加并发组合 |
| 渲染失败与状态一致性 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 定向组件测试入口 | `render-error` 返回值与 `visible` / `error` 事件时序是否一致 | `MapCanvas` 内部为何渲染失败 | 依赖结果本身异常时进入共享 UI owner 的渲染测试 |
| DTO 转换 | `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone` | 单元检查入口 | 启用标志、空 ID、坐标格式和最少点数的转换规则 | 服务响应真实性或地图呈现效果 | DTO 字段或 `MapZoneModel` 变化时同时检查 service 与共享契约 |

测试文件只说明预期与覆盖范围，不代表本次已经执行或当前实现必然符合预期。

## 文档维护信息

- 主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- 直接公共依赖声明：`packages/shared-ui/src/map-canvas/public.ts`
- 稳定验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`
- 当 Props、Emits、Slots、Expose、`HarborZoneResult`、请求淘汰语义、转换规则、地图公开契约或诊断信号变化时更新本文档。
