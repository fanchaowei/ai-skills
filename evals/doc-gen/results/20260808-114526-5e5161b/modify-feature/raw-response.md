已根据 `fixture/changes/modify-feature.diff` 更新电子围栏规则，并生成完整的 `ai-module-spec v3` 文档。

本次采用最小必要更新：将旧 v2 文档迁移到 v3 导航结构，移除调用方与瞬时测试状态，补齐 Props、Emits、Slots、Expose 四类 Vue 契约，并把 `normalizeZone()` 的有效边界点门槛更新为至少四个。文档同时保留了显隐编排、请求淘汰、地图渲染、直接公共依赖、数据流和稳定验证入口。

产物：

- `output/HarborMap.md`

需关注：变化集新增的 adapter 测试支持“四点有效”规则，但现有 `HarborMap.spec.ts` 仍以三个点预期显示成功。文档已将其记录为“模块内事实冲突”，未把相关测试描述为已通过。fixture 与 skill 均未修改，也未维护 fixture 内索引。
