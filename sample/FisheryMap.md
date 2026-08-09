---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: FisheryMap
module_type: complex-module
owner: apps/fishery-guardian-system
audience: ai
read_mode: progressive
depth: complex
summary: Fishery 地图业务门面，负责业务底图配置、地图命令转发、船舶历史轨迹和静态电子围栏编排

feature_index:
  base_map:
    entry: apps/fishery-guardian-system/src/components/fishery-map/FisheryMap.vue#switchBaseMap
    body_section: 功能目录/底图
  map_tools:
    entry: apps/fishery-guardian-system/src/components/fishery-map/FisheryMap.vue#startMeasure
    body_section: 功能目录/测量与绘图转发
  history_track:
    entry: apps/fishery-guardian-system/src/components/fishery-map/FisheryMap.vue#showBoatHistoryTrack
    body_section: 功能目录/历史轨迹
  electronic_fence:
    entry: apps/fishery-guardian-system/src/components/fishery-map/FisheryMap.vue#setElectronicFencesVisible
    body_section: 功能目录/电子围栏

detail_sections:
  scope: 模块边界
  contract: Vue 公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖
  diagnostics: 问题排查/症状索引
  data_flow: 数据转换与责任分层
  removal: 删除与保留边界

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# FisheryMap - 渔业地图业务门面

## 模块概述

`FisheryMap` 为 Fishery 应用注入 GCJ-02 默认视口与业务底图配置，向上提供稳定的 Vue 地图契约，并将通用测量、绘图、船舶历史轨迹和静态电子围栏能力编排到 `@shared/ui/MaptalksMap`。

模块只拥有 Fishery 侧的参数校验、API 边界、业务数据适配、并发淘汰和结果映射。通用地图图层、绘制状态机、轨迹渲染、电子围栏 Polygon/Label 生命周期与资源清理由 shared-ui 提供。

## 模块边界

### 模块拥有

| 路径 | 角色 | 当前职责 |
| --- | --- | --- |
| `apps/fishery-guardian-system/src/components/fishery-map/FisheryMap.vue` | `owned` | Vue 契约、地图命令转发、历史轨迹和电子围栏编排 |
| `apps/fishery-guardian-system/src/components/fishery-map/types/index.ts` | `owned` | Props、业务结果与 Expose 类型 |
| `apps/fishery-guardian-system/src/components/fishery-map/config/base-maps.ts` | `owned` | GCJ-02 默认视口、业务底图和加载配置 |
| `apps/fishery-guardian-system/src/components/fishery-map/adapters/boat-history-track.ts` | `owned` | 时间、AISID、船舶记录和点位适配 |
| `apps/fishery-guardian-system/src/components/fishery-map/adapters/electronic-fence.ts` | `owned` | 围栏过滤、坐标解析、样式归一和跳过计数 |
| `apps/fishery-guardian-system/src/components/fishery-map/utils/fishery-map-api.ts` | `owned` | `getTratoryData` 与 `getAreaHint` 请求边界 |
| `apps/fishery-guardian-system/src/components/fishery-map/__tests__/FisheryMap.spec.ts` | `owned` | 模块公开契约与编排行为的验证入口 |

### 明确排除

- 通过 `FisheryMap` 公开契约使用地图能力的页面、工具栏和业务对话框均为调用方，不属于本模块事实。
- shared-ui 内部 controller、图层实现、绘制状态机和渲染细节不属于本模块；这里只记录 `FisheryMap` 实际使用的公开契约。
- 点位交互、轨迹回放、时间轴、播放控制和移动船舶节点不属于当前模块能力。

## 功能目录

### 底图

- 入口：`apps/fishery-guardian-system/src/components/fishery-map/FisheryMap.vue#switchBaseMap`。
- 配置：`apps/fishery-guardian-system/src/components/fishery-map/config/base-maps.ts` 提供默认中心、缩放边界、业务底图与加载超时。
- 结果：通用地图返回结构化切换结果；未配置底图保持当前底图，不伪造可用状态。
- 验证：配置测试、组件转发测试与真实瓦片环境验收。

### 测量与绘图转发

- 入口：`startMeasure()`、`startAreaMeasure()`、`startBusinessDrawing()` 及对应停止或取消方法。
- 编排：`FisheryMap` 原样转发通用地图命令与 `businessDrawComplete`、`businessDrawCancel`、`mapToolStateChange`、`mapToolError` 等事件。
- 不变量：不在门面重复实现 DrawTool、面积计算、标签布局、工具互斥或资源清理。
- 验证：组件方法/事件测试；涉及通用工具状态机时扩大到 shared-ui 地图验证。

### 历史轨迹

- 入口：`apps/fishery-guardian-system/src/components/fishery-map/FisheryMap.vue#showBoatHistoryTrack`。
- 参数：`AISID` 为空字符串时查询全部船舶，非空时必须是正整数字符串；时间按 `YYYY-MM-DD HH:mm:ss` 和 Asia/Shanghai 语义校验。
- API：请求边界将内部 `mmsi` 映射为后端 `AISID`，使用 `getTratoryData`。
- 适配：按船舶保留后端顺序，过滤无效点，GCJ-02 坐标原值进入 shared-ui；船舶之间不得连接。
- 并发：查询、主动清除和卸载都会推进版本；只有最后一次调用可以绘制，旧调用返回 `superseded`。
- 结果：区分 `success`、`empty`、`invalid-params`、`request-error`、`map-not-ready`、`render-error` 和 `superseded`。
- 验证：组件编排、adapter、API wrapper 和 shared-ui 批量固定轨迹入口。

### 电子围栏

- 入口：`apps/fishery-guardian-system/src/components/fishery-map/FisheryMap.vue#setElectronicFencesVisible`。
- 显示：先清理旧围栏，确认清理成功且版本仍有效，再请求无参数 `getAreaHint`、适配数据并调用 shared-ui 围栏公开命令。
- 隐藏：推进版本并释放当前资源，不请求 API；清理失败向调用者传播。
- 适配：只保留 `isShow === '0'`、非空且批次内唯一的 `hintID`；`hintPos` 用 `_` 分点、`,` 分经纬度，少于三个不同有效点的记录被跳过。
- 样式：后端 `opacity` 映射为通用 `fillOpacity`；`hintType` 只保存在 metadata。
- 并发：隐藏、显示和卸载共享版本边界，每个异步阶段后检查；旧调用返回 `superseded`。
- 结果：在 shared-ui 渲染结果上增加 Fishery 侧 `request-error` 与 `superseded`。
- 验证：组件、围栏 adapter、API wrapper 与 shared-ui 围栏公开命令。

## Vue 公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialCenter` | `MapCoordinate` | `[121.5, 29.5]` | GCJ-02 初始中心 |
| `initialZoom` | `number` | `7` | 初始缩放 |
| `minZoom` / `maxZoom` | `number` | `3` / `18` | 缩放边界 |
| `initialBaseMap` | `FisheryBaseMapType` | `vector` | 初始业务底图 |
| `tileLoadTimeout` | `number` | `10000` | 候选底图加载超时 |

### Emits

- `businessDrawComplete`、`businessDrawCancel`：业务绘图完成与取消。
- `lineDrawComplete`、`lineDrawCancel`：旧线绘制兼容事件。
- `mapToolStateChange`：通用工具当前状态。
- `mapToolError`：通用绘图错误。
- 底图生命周期事件：原样转发 shared-ui 公开事件。

### Slots

无。

### Expose

```ts
interface FisheryMapExpose {
  switchBaseMap(type: FisheryBaseMapType): Promise<BaseMapSwitchResult>
  resetToInitialView(): Promise<void>
  startMeasure(): Promise<MapToolCommandResult>
  stopMeasure(): Promise<void>
  startAreaMeasure(): Promise<MapToolCommandResult>
  stopAreaMeasure(): Promise<void>
  startBusinessDrawing(options: BusinessDrawingOptions): Promise<MapToolCommandResult>
  cancelBusinessDrawing(): Promise<void>
  startLineDrawing(style?: LineDrawingStyle): Promise<MapToolCommandResult>
  cancelLineDrawing(): Promise<void>
  clearToolLayers(): Promise<void>
  showBoatHistoryTrack(options: ShowBoatHistoryTrackOptions): Promise<BoatHistoryTrackResult>
  clearBoatHistoryTrack(): Promise<void>
  setElectronicFencesVisible(visible: boolean): Promise<ElectronicFenceCommandResult>
}
```

## 直接公共依赖

| Provider | 实际使用的公开契约 | 模块内使用位置 |
| --- | --- | --- |
| `@shared/ui/MaptalksMap` | 底图切换、测量、业务绘图、工具状态事件和资源清理 | `FisheryMap.vue` |
| `MaptalksMapExpose.showHistoryTracks()` | 批量固定历史轨迹与结构化渲染结果 | `showBoatHistoryTrack()` |
| `MaptalksMapExpose.setElectronicFencesVisible()` | 通用围栏模型、显隐与结构化清理/渲染结果 | `setElectronicFencesVisible()` |

只依赖这些公开入口。shared-ui 内部 hook、controller、图层和回滚实现由其自身模块文档负责。

## 数据转换与责任分层

### 历史轨迹

`ShowBoatHistoryTrackOptions → fishery-map-api 请求参数 → 后端船舶记录 → boat-history-track adapter → shared-ui HistoryTrackModel[] → BoatHistoryTrackResult`

- API wrapper 负责接口 task、字段映射和业务响应边界。
- adapter 负责 AISID 选择、时间/点位校验、逐船分组和摘要。
- shared-ui 负责图层、箭头、视口与资源生命周期。
- `FisheryMap` 负责并发版本和公开结果映射。

### 电子围栏

`getAreaHint DTO → electronic-fence adapter → 通用围栏模型 → shared-ui command result → ElectronicFenceCommandResult`

- API wrapper 负责响应结构与请求错误。
- adapter 负责业务字段过滤、坐标与样式语义转换。
- shared-ui 负责 Polygon/Label 渲染与资源清理。
- `FisheryMap` 负责版本淘汰和 Fishery 结果扩展。

## 问题排查/症状索引

| 症状 | 功能域 | 第一检查点 | 稳定信号 | 下一验证入口 |
| --- | --- | --- | --- | --- |
| 底图切换后仍显示旧底图 | 底图 | `FisheryMap.vue#switchBaseMap` | 结构化 `unconfigured` 或切换结果 | 底图配置测试与瓦片环境 |
| 历史轨迹返回空结果 | 历史轨迹 | `FisheryMap.vue#showBoatHistoryTrack` | `empty`、AISID 匹配数、有效点数 | adapter 与 API wrapper 测试 |
| 历史轨迹旧请求覆盖新结果 | 历史轨迹 | `FisheryMap.vue#showBoatHistoryTrack` | 请求版本与 `superseded` | 并发组件测试 |
| 围栏请求成功但没有图形 | 电子围栏 | `electronic-fence.ts#normalizeElectronicFence` | 跳过数量、有效模型数、渲染结果 | adapter 与 shared-ui 命令验证 |
| 围栏隐藏后又出现 | 电子围栏 | `FisheryMap.vue#setElectronicFencesVisible` | 请求版本与 `superseded` | 显示/隐藏交错测试 |

第一检查点和稳定信号只用于缩小故障边界，不代表已确定根因。

## 状态与错误责任矩阵

| 状态 | 产生层 | FisheryMap 责任 | 公开语义 |
| --- | --- | --- | --- |
| `empty` | API 成功空数据或 adapter 无有效模型 | 保持与请求错误分离 | 当前没有可展示结果 |
| `request-error` | Fishery API 边界 | 转换网络、业务码或响应结构异常 | 请求链失败 |
| `map-not-ready` | shared-ui 公开命令 | 原样映射 | 地图未就绪 |
| `render-error` | shared-ui 渲染命令 | 原样映射或统一捕获 | 地图命令失败 |
| `superseded` | FisheryMap 版本检查 | 阻止旧调用回写最新状态 | 调用已被更新请求取代 |

## 删除与保留边界

| 分类 | 电子围栏能力 | 历史轨迹能力 |
| --- | --- | --- |
| owned remove | 对应 Expose、版本状态、API wrapper 分支、adapter、业务类型和模块测试 | 对应 Expose、版本状态、API wrapper 分支、adapter、业务类型和模块测试 |
| module-local adjust | 功能索引、诊断、状态矩阵、验证入口 | 功能索引、诊断、状态矩阵、验证入口 |
| direct dependency preserve | shared-ui 通用围栏公开能力 | shared-ui 通用轨迹公开能力 |

本模块删除清单不规划调用方变更，也不删除 shared-ui 通用能力。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 底图配置 | `config/base-maps` 配置测试 | 单元 | 默认视口、底图配置和超时映射 | 真实供应商可用性 | 瓦片地址或授权变化时增加环境验收 |
| Vue 契约与转发 | `FisheryMap.spec.ts` | 组件 | Props、Emits、Expose 与通用命令转发 | shared-ui 内部实现 | shared-ui 公开契约变化时扩大到跨包类型检查 |
| 历史轨迹转换 | `boat-history-track` adapter 与 API wrapper 测试 | 单元 | 参数、响应、点位和逐船模型转换 | 地图视觉效果 | 通用轨迹模型变化时增加 shared-ui 验证 |
| 电子围栏转换 | `electronic-fence` adapter 与 API wrapper 测试 | 单元 | 过滤、坐标、样式与请求错误边界 | Polygon/Label 视觉效果 | 通用围栏模型变化时增加 shared-ui 验证 |
| 并发与结果映射 | `FisheryMap.spec.ts` 的交错调用用例 | 组件 | 最后调用获胜和结果状态 | 网络取消与真实渲染时序 | 请求或命令支持取消时增加集成验证 |
| 地图视觉与交互 | 可登录业务环境 | 人工 | 图层、标签、底图、测量和绘制交互 | 自动化回归稳定性 | 样式、瓦片或地图内核变化时执行 |

模块文档记录的是稳定入口和证明范围；每次修改后仍需根据实际变化重新执行适用检查。

## 文档维护信息

- 文档类型：`ai-module-spec v3`。
- Owner：`apps/fishery-guardian-system`。
- 模块类型：`complex-module`。
- 更新模块当前事实、公开契约、路径或 symbol 时同步维护本文件。
- 调用方、实施历史和验证执行记录由各自模块、Git、CI 或当前任务报告维护。
