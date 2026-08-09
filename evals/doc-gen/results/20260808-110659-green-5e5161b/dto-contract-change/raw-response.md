已根据 `changes/dto-change.diff` 完成 HarborMap 模块文档更新，结果写入 `output/HarborMap.md`。

- 文档结构已从 `ai-module-spec v2` 升级为 v3，模块类型确认为详细 Vue 组件。
- 核心功能域为电子围栏显隐编排、后端响应契约吸收、围栏 DTO 归一化。
- 边界确认结果：组件、类型、service、adapter 与模块内测试属于 HarborMap；`HarborPage.vue` 是调用方并已排除；共享地图画布只记录实际使用的公开契约。
- DTO/响应变化的模块内吸收位置已明确：`types.ts#HarborZoneDto` 接收 `points → boundary`，`harbor-api.ts#HarborApiResponse` 接收数组型 `data → data.items`，`HarborMap.vue#setZonesVisible` 负责解包 `data.items`，`normalize-zone.ts#normalizeZone` 负责读取并转换 `boundary`。Vue Props、Emits、Slots、Expose 与 `HarborZoneResult` 保持稳定。
- 自检已覆盖 v3 YAML 固定字段、功能索引与正文入口、调用方排除、直接公共依赖、公开契约四类接口、数据责任分层和验证证明范围。
- 未自动处理事项：模块测试夹具仍使用旧的数组型 `data` 与 `points` 字段，文档已作为模块内事实冲突记录；任务仅要求更新文档，因此未修改测试代码。夹具未提供 owner/root 索引文件，且输出位置已被指定，未生成索引更新。
