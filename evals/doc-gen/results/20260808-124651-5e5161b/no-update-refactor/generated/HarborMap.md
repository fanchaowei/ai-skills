---
doc_type: ai-module-spec
spec_version: "2.0"
module_name: HarborMap
module_type: component
owner: apps/harbor-system
key_files:
  - apps/harbor-system/src/components/harbor-map/HarborMap.vue
  - apps/harbor-system/src/components/harbor-map/types.ts
  - apps/harbor-system/src/pages/HarborPage.vue
detail_sections:
  contract: 当前实现契约
  tests: 已验证行为
status: active
---

# HarborMap

> fixture 旧文档状态：本文档刻意保留 v2 边界污染、契约遗漏和瞬时状态，用于运行修改前的 Skill 基线。

## 模块边界

- `HarborMap.vue` 负责电子围栏查询、转换和地图渲染。
- `HarborPage.vue` 负责 checkbox 失败回退，并作为 HarborMap 当前实现的一部分记录。
- `packages/shared-ui/src/map-canvas/public.ts` 提供地图公开契约。

## 当前实现契约

- Props：`initialZoom?: number`。
- Emits：`zoneStatusChange`。
- Expose：`setZonesVisible(visible)`。
- 当前实现契约未记录 `toolbar` slot。

## 电子围栏

`setZonesVisible(true)` 请求围栏、通过 `normalizeZone()` 转换并调用 `replaceZones()`；隐藏时清除围栏。调用方 checkbox 在失败时回退未选中。

## 已验证行为

- `HarborMap.spec.ts`：passed。
