---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 编排港区电子围栏的读取、规范化、显隐渲染和并发淘汰，并通过公开组件契约返回结构化结果。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  request_supersession:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 并发请求淘汰
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  harbor_zone_fetch:
    entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones
    body_section: 港区围栏读取

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

# HarborMap - 港区电子围栏组件

## 模块概述

`HarborMap` 通过一个公开异步命令控制电子围栏显隐。显示链路读取港区围栏、过滤并转换数据、调用共享地图画布替换围栏；隐藏链路直接清除画布围栏。组件用单调递增的请求版本标记过期调用，但该标记只能约束模块自己的后续返回和事件，不能撤销已经进入共享画布的异步写入副作用。

## 模块边界

| 路径 | 角色 | 当前职责 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 组件契约、显隐编排、请求版本、状态映射和地图命令调用 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 港区 DTO、公开命令结果和 Expose 类型 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 港区 DTO 到地图围栏模型的过滤与转换 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 港区围栏响应契约和当前读取入口 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned verification | 模块内部组件测试入口，只证明预期和覆盖范围 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | `MapZoneModel` 与 `MapCanvasExpose` 的最小公开契约 |

调用方实现、状态、失败回退和测试不属于本模块事实。共享地图画布的内部实现也不属于本模块边界。

## 功能目录

### 电子围栏显隐编排

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 每次调用先递增模块内 `requestVersion`，并捕获本次 `currentVersion`。
- 地图 Expose 尚未可用时直接返回 `{ status: 'render-error' }`，不发出状态事件。
- `visible === false` 时不读取围栏，调用 `clearZones()`；清除完成且版本仍为最新时发出 `hidden`，返回成功且数量为 `0`。
- `visible === true` 时进入读取、规范化和替换链路；成功替换后发出 `visible`，并返回共享画布报告的数量。
- 组件对外只返回结构化 `HarborZoneResult`，不暴露服务响应或共享画布实例。

### 并发请求淘汰

入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`

- 显示链路在读取完成后、共享画布替换完成后各比较一次 `currentVersion` 与 `requestVersion`。
- 隐藏链路在清除完成后比较一次版本。
- 比较发现过期时返回 `{ status: 'superseded' }`，并跳过该检查点之后的成功事件或错误映射。
- 如果旧显示请求在新调用开始前已经通过读取后的版本检查并进入 `replaceZones()`，完成后的版本检查只能把旧调用的返回值标为 `superseded`；它不能撤销已经提交给共享画布的写入。
- 隐藏链路的 `clearZones()` 拒绝分支没有版本检查；旧隐藏请求在被新调用取代后仍可能发出 `error` 并返回 `render-error`。

### 围栏数据规范化

入口：`apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone`

- 仅接受 `enabled === '0'` 且去除空白后 `zone_id` 非空的 DTO。
- `points` 先按 `_` 拆分点，再按 `,` 转成数字坐标；不是两个有限数字的点被丢弃。
- 有效坐标少于三个时返回 `null`，否则生成 `{ id, coordinates }`。
- 显示链路过滤全部 `null`；没有剩余围栏时返回 `{ status: 'empty' }`，不调用共享画布，也不发出状态事件。

### 港区围栏读取

入口：`apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones`

- 返回 `Promise<HarborApiResponse>`，响应包含数值 `code` 和 `HarborZoneDto[]`。
- 组件只把 `code === 200` 视为可继续处理；其他 code 发出 `error` 并返回 `request-error`。
- 当前入口实现固定返回 `{ code: 200, data: [] }`。模块测试通过 mock 提供非空和可延迟响应；测试数据不改变生产入口的当前事实。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 原样传给 `MapCanvas` 的初始缩放值 |

### Emits

| 名称 | 载荷 | 发出条件 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 最新调用完成显示、完成隐藏，或进入当前实现的错误分支时发出；`empty`、`superseded` 和地图引用缺失不发出 |

### Slots

| 名称 | 语义 |
| --- | --- |
| `toolbar` | 渲染在地图画布之前的具名工具栏内容 |

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 的稳定状态为：

| status | 附加字段 | 模块语义 |
| --- | --- | --- |
| `success` | `count: number` | 最新调用完成显隐命令；隐藏固定返回 `0`，显示使用画布返回数量 |
| `empty` | 无 | 规范化后无围栏，或画布以 resolved 结果报告 `empty` |
| `request-error` | 无 | 非 200 响应，或显示链路 try 区域抛出/拒绝且调用仍为最新 |
| `render-error` | 无 | 地图 Expose 缺失、隐藏清除失败，或画布以 resolved 结果报告非成功且非 empty |
| `superseded` | 无 | 版本检查确认本次调用已被后续调用取代 |

## 直接公共依赖

Provider：`packages/shared-ui/src/map-canvas/public.ts`

| 公开 symbol | 本模块实际使用的最小契约 | 吸收位置 |
| --- | --- | --- |
| `MapZoneModel` | `{ id: string; coordinates: Array<[number, number]> }` | `normalizeZone()` 的成功结果 |
| `MapCanvasExpose.replaceZones` | 接收 `MapZoneModel[]`，异步返回 `success/count`、`empty` 或 `render-error` | 显示链路的地图替换边界 |
| `MapCanvasExpose.clearZones` | 无参数异步清除，返回 `Promise<void>` | 隐藏链路的地图清除边界 |

公开契约没有请求版本、取消句柄、调用标识、串行保证或最终画布快照，因此本模块不能仅凭 `replaceZones()` 的返回状态证明并发写入后的最终视觉数据。

## 数据转换与责任分层

### 显示链路

`setZonesVisible(true)` → `fetchHarborZones()` → 校验请求版本和响应 code → `normalizeZone()`/过滤 → `MapCanvasExpose.replaceZones()` → 再次校验请求版本 → 映射结果并发出事件。

### 隐藏链路

`setZonesVisible(false)` → `MapCanvasExpose.clearZones()` → 校验请求版本 → 映射结果并发出事件。

责任边界：服务入口拥有港区响应形状，adapter 拥有 DTO 过滤与模型转换，组件拥有调用排序、过期判断和公开结果映射，共享地图画布拥有实际围栏写入与清除副作用。

## 状态与错误责任矩阵

| 阶段 | 条件 | 返回 | 事件 | 责任边界 |
| --- | --- | --- | --- | --- |
| 初始化 | `mapCanvasRef` 不可用 | `render-error` | 无 | 组件 |
| 隐藏 | `clearZones()` 完成且仍为最新 | `success/count: 0` | `hidden` | 组件编排 + 画布清除 |
| 隐藏 | 清除完成后已过期 | `superseded` | 无 | 组件版本判断 |
| 隐藏 | `clearZones()` 拒绝 | `render-error` | `error` | 画布拒绝进入组件隐藏 catch；catch 不区分过期 |
| 显示读取 | 读取完成后已过期 | `superseded` | 无 | 组件版本判断 |
| 显示读取 | response code 非 200 | `request-error` | `error` | 服务响应到组件映射 |
| 规范化 | 没有有效围栏 | `empty` | 无 | adapter + 组件过滤 |
| 地图替换 | resolved `success` 且仍为最新 | `success/count` | `visible` | 画布结果到组件映射 |
| 地图替换 | resolved `empty` 且仍为最新 | `empty` | `error` | 组件当前映射 |
| 地图替换 | resolved `render-error` 且仍为最新 | `render-error` | `error` | 组件当前映射 |
| 显示 try 区域 | 任意抛出/拒绝且仍为最新 | `request-error` | `error` | 组件宽 catch，不能从返回值区分读取与渲染拒绝 |
| 任一版本检查 | 已被后续调用取代 | `superseded` | 无 | 只约束检查后的组件行为，不回滚既有外部副作用 |

## 问题排查与症状索引

### 症状：旧请求结果覆盖新请求

- 第一检查点：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` 中读取后的版本检查与 `replaceZones()` 调用之间。先确认旧调用是否已经通过该检查并进入共享画布，再确认两个 `replaceZones()` Promise 的完成顺序。
- 稳定结构化信号：旧调用在后置版本检查处返回 `{ status: 'superseded' }`；旧调用不应在该检查之后发出 `visible` 或映射 resolved 错误结果。这个信号只证明组件识别到过期，不证明画布中的旧写入没有晚于新写入完成。
- 故障边界：调用 `replaceZones()` 之前的版本判断和调用时机属于 `HarborMap`；进入 `MapCanvasExpose.replaceZones()` 后的实际地图变更属于共享画布。当前公开依赖契约没有取消或 last-write-wins 保证，最终视觉状态不能由 `HarborZoneResult` 单独判定。
- 下一验证入口：`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。使用两个可控的读取 Promise 让旧调用先进入 `replaceZones()`，再让新调用进入并先完成替换，最后让旧替换完成；测试桩同时记录每次完成后代表的画布 zone id，并分别断言最终记录、两个调用结果和 `zoneStatusChange`。该交错能覆盖现有“旧读取较晚、只有一次 replace”用例没有覆盖的渲染重叠窗口。
- 扩大验证条件：若修复依赖共享画布提供请求标识、取消、串行化或最终状态读取，需要在 `packages/shared-ui` 增加对应公开契约与跨 owner 集成验证；不能通过读取 provider 内部实现把这些语义补进本模块文档。

### 症状：新操作后仍收到旧隐藏操作的 error

- 第一检查点：隐藏分支 `clearZones()` 的 catch；该分支没有比较 `currentVersion`。
- 稳定结构化信号：旧隐藏调用返回 `render-error` 并发出 `zoneStatusChange('error')`，而不是 `superseded`。
- 下一验证入口：在 `HarborMap.spec.ts` 中延迟并拒绝旧 `clearZones()`，在拒绝前启动新调用，覆盖错误事件是否仍由过期调用发出。

## 跨功能风险

- `requestVersion` 是显示和隐藏共用的单一淘汰序列；任意后续显隐调用都会使前一调用在下一个版本检查点过期。
- 版本检查只保护组件检查点之后的控制流，不提供对已开始共享画布命令的取消、互斥或回滚。
- 显示链路的宽 catch 把 `fetchHarborZones()`、规范化过程和 rejected `replaceZones()` 统一映射为 `request-error`；仅凭公开结果不能稳定定位抛出阶段。
- resolved `MapZoneCommandResult.status === 'empty'` 会发出 `error`，而规范化后为空直接返回 `empty` 且不发事件；相同公开返回状态具有不同事件语义。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| adapter | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` 及针对 `normalizeZone` 的模块单元用例 | 单元/组件 | 输入过滤后是否进入画布替换、空结果的组件语义 | 未独立覆盖的所有坐标边界组合 | 修改 enabled、点格式或最小点数规则 | 可构造稳定 DTO 输入 |
| 组件契约 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | `initialZoom`、`toolbar`、Expose、事件与隐藏基本链路的预期 | 调用方状态和回退逻辑 | Props、Emits、Slots 或 Expose 变化 | Vue Test Utils 可挂载组件并替换 MapCanvas |
| 并发交互 | `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | 组件 | 延迟读取下仅最新读取进入替换的预期；加入可控替换后可覆盖渲染重叠时序 | 共享画布真实实现的最终视觉副作用 | 两次画布命令可重叠，或淘汰策略变化 | 服务和画布 Promise 的完成顺序可控 |
| service | `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones` 的服务测试入口 | 单元/集成 | 响应 code 和 DTO 形状的服务契约 | 地图转换、渲染和事件语义 | 接入真实传输、鉴权或响应解码 | 服务边界可独立替换或模拟 |
| 跨 owner 地图契约 | `packages/shared-ui/src/map-canvas/public.ts` 对应的 provider 契约/集成测试 | 集成/类型 | `replaceZones`、`clearZones` 和结果联合类型的公开语义 | `HarborMap` 的请求版本与事件映射 | 新增取消、请求 id、串行或最终状态契约 | provider 公开声明与运行实现保持一致 |

现有组件测试稳定覆盖“旧读取尚未进入替换时被新读取淘汰”的预期，因为该用例只允许一次 `replaceZones()`。它不覆盖两个替换都已开始且旧替换最后完成的窗口，也不能观察真实共享画布的最终视觉状态。

## 文档维护信息

- 文档 owner：`apps/harbor-system`
- 主入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- 边界复核时优先从主入口沿内部 import 到 types、adapter、service 和模块测试；调用方不纳入。
- 直接依赖契约变化只读取 `packages/shared-ui/src/map-canvas/public.ts` 的公开声明，不扩展到 provider 内部实现。
