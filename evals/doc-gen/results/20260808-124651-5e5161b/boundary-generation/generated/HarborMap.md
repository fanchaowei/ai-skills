---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: complex-module
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: detailed
summary: HarborMap 通过公开显隐命令获取、规范化并同步港区电子围栏到共享地图画布，同时收敛并发请求和结果状态。

feature_index:
  zone_visibility:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 电子围栏显隐编排
  zone_fetching:
    entry: apps/harbor-system/src/components/harbor-map/services/harbor-api.ts#fetchHarborZones
    body_section: 围栏数据获取
  zone_normalization:
    entry: apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts#normalizeZone
    body_section: 围栏数据规范化
  request_supersession:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 并发请求淘汰
  map_canvas_sync:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible
    body_section: 地图画布同步与结果收敛

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  risks: 跨功能风险
  dependencies: 直接公共依赖
  diagnostics: 状态与故障诊断
  data_flow: 数据转换与责任分层

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港区电子围栏地图模块

## 模块概述

`HarborMap` 是 `apps/harbor-system` 拥有的复杂 Vue 组件模块。组件渲染共享地图画布，并通过公开的 `setZonesVisible` 方法负责电子围栏的隐藏、获取、规范化、替换、并发淘汰、结果返回和状态事件收敛。

模块当前内置的数据服务 `fetchHarborZones` 返回 `{ code: 200, data: [] }`；因此在未替换该服务行为时，显示命令会在规范化后得到空集合并返回 `empty`，不会调用地图画布的 `replaceZones`。

## 模块边界

仓库根为 `fixture/` 对应的内容根；下表中的路径均相对该仓库根。用户指定目录内只有一个由真实 import 和模块内测试连接的功能所有者，边界无需额外确认。

| 路径 | 角色 | 边界证据 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | Vue 主入口；拥有组件公开契约、请求版本状态和显隐编排。 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 被主入口、服务、适配器和模块内测试直接引用，定义模块专属 DTO、返回结果和 expose 类型。 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 仅为本模块提供电子围栏响应契约和数据获取入口，并被主入口直接调用。 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 把本模块 DTO 转换为地图画布公开模型，并被主入口直接调用。 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned | 模块内部组件测试，直接验证主入口的稳定公开行为。 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 提供本模块真实使用的 `MapCanvasExpose`、`MapZoneModel` 和命令结果公开声明；不属于 HarborMap。 |

边界外处理：

- `@shared/ui/map-canvas` 的实现归共享 UI provider 所有；本文只记录 HarborMap 实际使用的 prop、模型和 expose 方法。
- 使用 `HarborMap` 的页面、父组件及其状态、回退、测试和排障逻辑均为 caller，始终不属于本模块文档。
- 不因目录相邻、名称相似或搜索命中扩展边界。

## 功能目录

### 电子围栏显隐编排

真实入口为 `HarborMap.vue#setZonesVisible(visible)`：

1. 每次调用先递增模块内 `requestVersion`，并捕获当前版本。
2. 地图画布 ref 不可用时直接返回 `{ status: 'render-error' }`。
3. `visible === false` 时不请求围栏数据，调用 `MapCanvasExpose.clearZones()`；未被新请求淘汰时发出 `zoneStatusChange: hidden`，返回 `{ status: 'success', count: 0 }`。
4. `visible === true` 时依次执行数据获取、响应码判断、DTO 规范化、无效围栏过滤和画布替换；最终返回 `HarborZoneResult`。

最小事实链：`setZonesVisible` → `requestVersion`/`mapCanvasRef` → `fetchHarborZones` 或 `clearZones` → `normalizeZone`/`replaceZones` → 返回结果与 `zoneStatusChange` → `HarborMap.spec.ts`。

### 围栏数据获取

`services/harbor-api.ts#fetchHarborZones` 返回 `Promise<HarborApiResponse>`；响应包含数字 `code` 和 `HarborZoneDto[]`。显示链路只接受 `code === 200`，其他响应码映射为 `request-error` 并发出 `error` 事件。函数抛错也由显示编排捕获并映射为 `request-error`，但被新请求淘汰的异常只返回 `superseded`。

当前服务实现固定返回成功码和空数组。该入口没有读取 caller 状态，也没有在模块外保存缓存。

### 围栏数据规范化

`adapters/normalize-zone.ts#normalizeZone` 把 `HarborZoneDto` 转为 `MapZoneModel | null`：

- 只接收 `enabled === '0'` 且去除首尾空白后非空的 `zone_id`。
- 以 `_` 拆分点，以 `,` 拆分经纬值，并用 `Number` 转换。
- 只保留恰有两个有限数字的坐标点。
- 有效坐标少于 3 个时返回 `null`；否则保留原始 `zone_id` 作为模型 `id`。

主入口通过 `map(normalizeZone).filter(zone !== null)` 丢弃无效 DTO。规范化后没有有效围栏时返回 `empty`，不调用 `replaceZones`，也不发出状态事件。

### 并发请求淘汰

`requestVersion` 为组件实例内的递增整数。`setZonesVisible` 在 `clearZones`、`fetchHarborZones` 和 `replaceZones` 等异步阶段之后比较捕获版本与最新版本；不一致时返回 `superseded`，不继续发出成功或错误事件。

该策略能阻止已经变旧且尚未进入下一阶段的请求继续提交结果；它不取消已经启动的 provider 异步操作，相关限制见“跨功能风险”。

### 地图画布同步与结果收敛

显示链路把规范化后的 `MapZoneModel[]` 传给 `MapCanvasExpose.replaceZones`：

- provider 返回 `success` 时，模块发出 `visible`，并把 provider 的 `count` 作为 `{ status: 'success', count }` 返回。
- provider 返回 `empty` 时，模块发出 `error`，但方法结果保持为 `{ status: 'empty' }`。
- provider 返回 `render-error` 或调用抛错时，模块发出 `error` 并返回 `render-error`。
- 隐藏链路成功时发出 `hidden`；`clearZones` 抛错时发出 `error` 并返回 `render-error`。
- ref 不可用时返回 `render-error`，当前实现不发出事件。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`，可选 | `12` | 原样传给 `MapCanvas` 的 `initial-zoom`。 |

### Emits

| 事件 | 载荷 | 发出条件 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 围栏替换成功、清空成功，或已收敛为请求/渲染错误时发出；`empty`、`superseded` 和 ref 不可用并非都产生事件，详见功能目录。 |

### Slots

| 名称 | Slot props | 渲染位置 |
| --- | --- | --- |
| `toolbar` | 无 | `.harbor-map` 容器内、`MapCanvas` 之前。 |

默认 slot：无。其他命名 slot：无。

### Expose

```ts
setZonesVisible(visible: boolean): Promise<HarborZoneResult>
```

`HarborZoneResult` 为：

```ts
type HarborZoneResult =
  | { status: 'success'; count: number }
  | { status: 'empty' }
  | { status: 'request-error' }
  | { status: 'render-error' }
  | { status: 'superseded' }
```

其他 expose：无。

## 直接公共依赖

| Provider | 本模块使用的最小契约 | 模块内入口 |
| --- | --- | --- |
| `@shared/ui/map-canvas` | Vue 组件接收 `initialZoom`；实例提供 `clearZones()` 和 `replaceZones(zones)`。 | `HarborMap.vue` 模板与 `mapCanvasRef` |
| `@shared/ui/map-canvas/public` | `MapZoneModel { id, coordinates }`、`MapCanvasExpose`；替换结果为 `success(count)`、`empty` 或 `render-error`。 | `HarborMap.vue`、`adapters/normalize-zone.ts` |

HarborMap 不拥有 provider 的渲染实现，也不扩写 provider 如何绘制、清空或计算数量。

## 数据转换与责任分层

| 层级 | 输入 | 转换或责任 | 输出 |
| --- | --- | --- | --- |
| 模块服务 | 无调用参数 | 获取 Harbor API 形态响应 | `{ code, data: HarborZoneDto[] }` |
| 模块适配器 | `HarborZoneDto` | 启用态、标识和坐标合法性过滤；字符串坐标转数值元组 | `MapZoneModel \| null` |
| 组件编排 | API 响应和有效模型数组 | 响应码判断、空集合收敛、并发版本检查 | provider 命令或 `HarborZoneResult` |
| 共享画布公开契约 | `MapZoneModel[]` | 执行替换或清空；内部渲染不属于本模块 | `MapZoneCommandResult` 或完成信号 |
| 组件公开结果 | provider 结果或异常 | 映射为 HarborMap 状态并按条件发出事件 | `HarborZoneResult`、`zoneStatusChange` |

## 状态与故障诊断

| 公开结果 | 模块内触发条件 | 第一检查点 | 下一验证入口 |
| --- | --- | --- | --- |
| `success` | 清空完成，或画布替换返回 `success` | `HarborMap.vue#setZonesVisible` 的隐藏/显示分支 | `__tests__/HarborMap.spec.ts`；需要 provider 语义时转查共享画布契约 |
| `empty` | 规范化后无有效围栏，或 provider 返回 `empty` | `normalizeZone` 过滤结果与 `replaceZones` 返回值 | 为 adapter 空/非法输入增加单元覆盖，或扩展组件测试的 empty 分支 |
| `request-error` | 响应码非 200，或数据服务抛错且请求仍是最新版本 | `fetchHarborZones` 响应与显示分支 catch | 组件测试中的服务 mock 分支；真实接口问题属于集成验证范围 |
| `render-error` | ref 不可用、清空抛错、替换抛错或 provider 返回渲染错误 | `mapCanvasRef`、`clearZones`、`replaceZones` | 组件测试的 stub 失败分支；真实绘制问题转查 provider 验证入口 |
| `superseded` | 任一受检查的异步阶段完成后发现版本已落后 | `requestVersion` 比较点 | `HarborMap.spec.ts` 的并发请求用例，并按扩大条件补充跨阶段竞态用例 |

这些结果是结构化定位信号，不单独证明根因。

## 跨功能风险

- `requestVersion` 只能在 await 返回后停止后续编排，不能取消已经开始的 `clearZones` 或 `replaceZones`。若新请求在旧画布操作进行中启动，旧 provider 操作仍可能产生副作用；涉及该时序的改动应扩大为可控 promise 的竞态验证。
- `enabled === '0'` 被模块解释为可显示围栏。该值语义同时影响过滤和最终空结果；变更 DTO 枚举时必须同步 adapter、服务契约和覆盖范围。
- 空结果的事件语义并不统一：规范化为空时不发事件，provider 返回 `empty` 时发 `error`。依赖事件的公开行为变更应同时核对方法结果与 emit 契约。

## 验证入口与证明范围

稳定的模块内验证入口为 `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件显隐编排 | `HarborMap.spec.ts` 的 `does not request zones when hiding` | 组件单元 | 隐藏命令预期不取数、调用清空并返回成功计数 0。 | 真实画布是否已经清除，以及清空失败分支。 | 改动 `clearZones` 映射、事件或 provider 契约时补充失败和集成覆盖。 |
| 并发淘汰 | `HarborMap.spec.ts` 的 `keeps only the latest visible request result` | 组件单元 | 两个待决取数请求中较新结果预期进入替换，较旧结果预期为 `superseded`。 | 已经进入 `clearZones`/`replaceZones` 的跨阶段竞态、取消能力和真实网络时序。 | 改动版本检查点或 provider 异步边界时增加可控竞态矩阵。 |
| Vue 公开契约 | `HarborMap.spec.ts` 的 `exposes props emits slots and setZonesVisible` | 组件单元 | 显式 prop、`toolbar` slot、expose 方法和隐藏成功事件的预期形态。 | `initialZoom` 默认值、显示/错误事件以及所有返回状态。 | 改动 Props、Emits、Slots、Expose 任一项时扩展契约用例。 |
| DTO 规范化 | `normalize-zone.ts`，当前无独立测试文件 | 单元候选入口 | 通过静态契约可定位启用态、标识、坐标拆分和最少点数规则。 | 现有组件测试未精确断言过滤后的坐标载荷，也不覆盖非法输入组合。 | 改动 DTO 或画布模型时增加 adapter 参数化单元测试。 |
| 服务与真实集成 | `harbor-api.ts#fetchHarborZones`，组件测试通过 mock 隔离 | 集成候选入口 | 公开响应形态和组件对 code/data 的消费边界可定位。 | 真实请求、鉴权、网络失败、后端字段兼容性和部署环境。 | 服务从固定响应接入真实 transport，或跨 owner API 契约变化时增加集成验证。 |
| 共享画布交互 | 组件测试中的 `MapCanvasStub` | 组件单元 | HarborMap 预期调用 `clearZones`/`replaceZones` 并消费公开结果。 | 共享画布的真实渲染、几何表现、性能和浏览器交互。 | 修改 `MapCanvasExpose`、模型结构或视觉行为时转查 provider 测试并增加人工地图验收。 |

长期前提：组件测试需要 Vue Test Utils 与 Vitest 环境，并通过可控 stub/mock 隔离共享画布和模块服务。本文不把测试文件的期望等同于当前实现符合预期，也不记录某次执行状态。

## 文档维护信息

- 事实 owner：`apps/harbor-system`
- 模块入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- 关键电子围栏入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible`
- 维护触发：Vue 四类公开契约、`HarborZoneResult`、DTO/坐标规则、响应码映射、并发版本检查点或 `MapCanvasExpose` 最小契约变化。
- 文档不纳入 caller、共享画布内部实现、历史阶段或瞬时验证状态。
