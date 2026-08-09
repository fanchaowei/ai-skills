---
doc_type: ai-module-spec
spec_version: "3.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
audience: ai
read_mode: progressive
depth: simple
summary: HarborMap 提供带默认缩放配置和工具栏插槽的 MapCanvas 容器。

feature_index:
  map_canvas_hosting:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue
    body_section: 地图画布承载
  toolbar_extension:
    entry: apps/harbor-system/src/components/harbor-map/HarborMap.vue
    body_section: 工具栏插槽扩展

detail_sections:
  scope: 模块边界
  contract: 当前公开契约
  verification: 验证入口与证明范围
  dependencies: 直接公共依赖

status: active
last_updated: "2026-08-09"
last_updated_by: doc-gen
---

# HarborMap - 简单 Vue 组件

## 模块概述

`HarborMap` 是港口地图的轻量容器组件。它接收初始缩放级别，渲染共享 `MapCanvas`，并在地图上方提供具名工具栏插槽。

## 模块边界

- 主入口及唯一 owned 文件：`apps/harbor-system/src/components/harbor-map/HarborMap.vue`。
- 模块负责 Props 默认值、工具栏插槽位置和 `MapCanvas` 组件编排。
- 模块当前不拥有电子围栏查询、数据转换、地图围栏命令、并发请求状态或对外暴露方法。
- 上层页面属于调用方；其状态、交互和回退逻辑不属于本模块事实。

## 功能目录

### 地图画布承载

事实链：

1. `HarborMap.vue` 通过 `initialZoom` Prop 接收初始缩放级别。
2. `withDefaults` 在调用方未传值时将其设为 `12`。
3. 模板把 `initialZoom` 传给共享 `MapCanvas` 的同名 Prop。
4. 公开结果是在 `.harbor-map` 容器内渲染地图画布。
5. 稳定验证入口是对 `HarborMap.vue` 的组件契约与模板绑定检查。

### 工具栏插槽扩展

事实链：

1. `HarborMap.vue` 声明具名 `toolbar` Slot。
2. 模板在 `MapCanvas` 之前渲染该插槽内容。
3. 公开结果是调用方可向地图容器顶部注入工具栏内容；模块不处理插槽内容的状态或事件。
4. 稳定验证入口是对 `HarborMap.vue` 的 Slot 声明与模板位置检查。

## 当前公开契约

### Props

| 名称 | 类型 | 默认值 | 语义 |
| --- | --- | --- | --- |
| `initialZoom` | `number`（可选） | `12` | 传递给 `MapCanvas` 的初始缩放级别。 |

### Emits

| 名称 | 载荷 | 当前模块行为 |
| --- | --- | --- |
| `zoneStatusChange` | `'visible' \| 'hidden' \| 'error'` | 组件保留该事件声明，但当前实现没有触发该事件。 |

### Slots

| 名称 | Slot Props | 语义 |
| --- | --- | --- |
| `toolbar` | 无 | 在地图画布之前插入工具栏内容。 |

### Expose

无。

## 直接公共依赖

| Provider | 目标模块实际使用的最小契约 | 模块内使用入口 |
| --- | --- | --- |
| `@shared/ui/map-canvas` 的默认导出 `MapCanvas` | 作为 Vue 子组件渲染，并接收 `initialZoom` Prop。 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` |

模块不调用 `MapCanvas` 的电子围栏命令，也不依赖其围栏模型或命令结果类型。

## 验证入口与证明范围

| 改动层级 | 检查入口 | 检查类型 | 能证明 | 不能证明 | 扩大条件 | 长期前提 |
| --- | --- | --- | --- | --- | --- | --- |
| 组件公开契约与模板编排 | `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | 人工静态检查 | Props、Emits、Slots、Expose 声明，以及 `initialZoom` 默认值和模板传递关系。 | 浏览器中的实际渲染、共享组件内部行为或调用方集成。 | 修改 `MapCanvas` 公共契约、插槽布局或新增交互时，需要增加组件或集成测试入口。 | 可读取 Vue SFC 与 TypeScript 类型声明。 |

当前模块边界内没有专属自动化测试文件；因此没有可记录的模块级单元或组件测试入口。

## 文档维护信息

- 事实来源：当前模块入口 `apps/harbor-system/src/components/harbor-map/HarborMap.vue`。
- 维护时优先核对 Vue 四类公开契约、`MapCanvas` 绑定和功能目录入口。
- `feature_index` 只指向当前存在的 owned 文件，不包含调用方或已失效实现路径。
