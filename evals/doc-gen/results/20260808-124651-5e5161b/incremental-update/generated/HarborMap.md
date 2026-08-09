---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: simple
summary: "提供港区地图容器，公开初始缩放配置、区域状态事件声明和工具栏插槽，并渲染共享地图画布。"

feature_index:
  map_canvas_rendering:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue
    body_section: 地图画布渲染
  toolbar_slot:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue
    body_section: 工具栏插槽

detail_sections:
  scope: 模块边界
  contract: Vue 公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - Vue 组件

## 模块概述

`HarborMap` 是港区地图的轻量容器组件，负责向共享地图画布传入初始缩放级别，并在画布上方提供工具栏插槽。

## 模块边界

| 角色 | 路径或依赖 | 当前责任 |
| --- | --- | --- |
| owned | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 定义 Vue 公开契约和地图容器模板 |
| direct-public-dependency | `@shared/ui/map-canvas` | 提供默认导出的 `MapCanvas` 子组件；本模块只传入初始缩放参数 |

当前模块边界只包含上述单个组件文件，没有其他 `owned` 文件。

## 功能目录

### 地图画布渲染

- 入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- 组件渲染 `MapCanvas`，并将 `initialZoom` 绑定为子组件的 `initial-zoom`。
- `initialZoom` 未传入时使用默认值 `12`。

### 工具栏插槽

- 入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`
- 命名插槽 `toolbar` 位于 `MapCanvas` 之前，用于注入地图上方的工具内容。

## Vue 公开契约

### Props

| 名称 | 类型 | 必填 | 默认值 | 说明 |
| --- | --- | --- | --- | --- |
| `initialZoom` | `number` | 否 | `12` | 传递给 `MapCanvas` 的初始缩放级别 |

### Emits

| 名称 | 参数 | 当前语义 |
| --- | --- | --- |
| `zoneStatusChange` | `status: 'visible' \| 'hidden' \| 'error'` | 公开事件声明仍存在；当前组件内部没有触发该事件的实现入口 |

### Slots

| 名称 | Slot Props | 说明 |
| --- | --- | --- |
| `toolbar` | 无 | 在地图画布之前渲染工具内容 |

### Expose

无。

## 直接公共依赖

| Provider | 公开入口 | 本模块实际使用的最小契约 | 模块内吸收位置 |
| --- | --- | --- | --- |
| `@shared/ui/map-canvas` | 默认导出 `MapCanvas` | 接收 `initial-zoom` 并作为子组件渲染；本模块不使用地图实例命令或区域模型类型 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` 模板 |

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| Vue 公开契约与模板绑定 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | Vue/TypeScript 静态检查 | Props、Emits、Slots、Expose 声明及 `initial-zoom` 模板绑定可被解析 | `MapCanvas` 的运行时渲染效果和事件实际触发 | 共享组件契约变化时增加跨 owner 契约检查 | 使用 owner 配置的 Vue/TypeScript 检查入口；fixture 未提供具体命令 |

当前模块边界内没有专属测试文件，因此没有稳定的组件交互自动化验证入口。

## 文档维护信息

- 主要维护入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`。
- 更新公开契约时，同步核对 YAML `feature_index`、正文“功能目录”和“Vue 公开契约”。
