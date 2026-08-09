已根据 `fixture/changes/dto-change.diff` 完成 HarborMap 模块文档更新，产物为 `output/HarborMap.md`。

分析结论：

- DTO 字段变化应由 `apps/harbor-system/src/components/harbor-map/types.ts` 声明为 `boundary`，并由 `adapters/normalize-zone.ts#normalizeZone` 在 DTO → `MapZoneModel` 的边界处吸收；共享地图模型仍只接收 `id + coordinates`，无需改动。
- 响应契约变化应由 `services/harbor-api.ts` 声明 `{ code, data: { items } }`，组件在 `HarborMap.vue#setZonesVisible` 中校验 `code` 并从 `response.data.items` 解包列表。service 不承担地图转换，adapter 不承担响应包裹解包。
- `HarborMap.vue` 继续只负责显隐编排、并发淘汰、错误映射和地图命令；Vue 对外契约保持为 `initialZoom`、`zoneStatusChange`、`toolbar` slot 与 `setZonesVisible()`。
- `packages/shared-ui/src/map-canvas/public.ts` 是直接公共依赖，但本次后端 DTO/响应变化没有改变 `MapZoneModel` 或 `MapCanvasExpose`，因此不应把后端字段或包裹结构扩散到共享 UI owner。
- `apps/harbor-system/src/pages/HarborPage.vue` 是调用方，已从模块事实中排除；旧文档中关于调用方回退的内容未保留。
- 内部 `HarborMap.spec.ts` 的可见请求夹具仍使用旧 `data[] + points` 形状，与变化集中的 `data.items + boundary` 冲突。更新后的文档将其明确限制为并发意图/旧覆盖范围证据，不把它当作新后端契约已经被验证的证据。

文档已从 `ai-module-spec v2` 升级为 v3，补齐了模块边界、Props/Emits/Slots/Expose、核心功能事实链、直接公共依赖、DTO/响应责任分层、状态与错误语义、跨功能风险以及稳定验证入口。现有文档位置已符合 monorepo owner 路由，无需迁移或维护其他索引；未修改 `fixture/` 或 `skill/`。

执行未遇到内容层面的阻塞。
