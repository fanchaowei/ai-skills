---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: simple
summary: HarborMap 提供港区地图画布容器、初始缩放级别转发和工具栏插槽扩展。

feature_index:
  map_canvas_rendering:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue
    body_section: 地图画布渲染
  toolbar_extension:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue
    body_section: 工具栏插槽扩展

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖

status: active
last_updated: "2026-08-08"
last_updated_by: doc-gen
---

# HarborMap - 港区地图组件

## 模块概述

`HarborMap` 是港区地图的轻量容器组件。它向地图画布传递初始缩放级别，并在画布上方提供工具栏插槽。

## 模块边界

- 模块入口为 `apps/harbor-system/src/components/harbor-map/HarborMap.vue`。
- 模块拥有港区地图容器结构、`initialZoom` 默认值及其向 `MapCanvas` 的转发，以及 `toolbar` 插槽落点。
- 模块不包含电子围栏数据查询、数据转换、区域显隐编排或地图画布实例命令。
- `@shared/ui/map-canvas` 是直接公共依赖；其内部实现不属于本模块。
- 使用 `HarborMap` 的页面和其他调用方不属于本模块。

## 功能目录

### 地图画布渲染

- 入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`。
- 组件渲染 `section.harbor-map` 容器，并在其中挂载 `MapCanvas`。
- `initialZoom` 未传入时取默认值 `12`，随后作为 `MapCanvas` 的 `initial-zoom` 属性传入。
- 本功能没有模块内状态、数据转换或地图实例 Expose 调用。

### 工具栏插槽扩展

- 入口：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`。
- 命名插槽 `toolbar` 渲染在 `MapCanvas` 之前。
- 插槽内容由调用方提供；调用方的状态与交互逻辑不属于本模块。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`（可选） | `12` | 传递给 `MapCanvas` 的初始缩放级别。 |

### Emits

| 名称 | 参数 | 当前模块内触发 |
| --- | --- | --- |
| `zoneStatusChange` | `status: 'visible' \| 'hidden' \| 'error'` | 组件保留该事件声明，但当前实现没有调用发射入口。 |

### Slots

| 名称 | Slot Props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 在地图画布之前插入工具栏内容。 |

### Expose

无。

## 直接公共依赖

| Provider | 使用的公开入口 | 模块内输入 | 模块内使用位置 |
| --- | --- | --- | --- |
| `@shared/ui/map-canvas` | 默认导出的 `MapCanvas` 组件 | `initialZoom` 作为 `initial-zoom` 属性 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` |

本模块不引用 `MapCanvasExpose`，也不调用区域替换或清除等地图实例方法。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 |
| --- | --- | --- | --- | --- | --- |
| 组件契约与模板结构 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 静态检查 | Props 默认值、Emits 声明、Slots、Expose 缺失状态、模板顺序和 `initialZoom` 转发关系 | `MapCanvas` 的运行时渲染行为或调用方交互 | `MapCanvas` 公开契约变化时增加 shared-ui 侧契约检查；新增组件交互时增加组件级验证入口 |

## 文档维护信息

- 公开契约、模板结构或 `MapCanvas` 使用方式变化时更新本文档。
- 功能索引只指向模块拥有的当前入口，不纳入调用方或共享组件内部实现。
