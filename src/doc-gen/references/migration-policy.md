# 历史文档迁移策略

## 格式版本

- 新生成模块文档使用 `ai-module-spec v3`。
- 用户要求更新、重写、升级、按新模板整理，或任务要求产出、写入、维护完整模块文档时，将 v1/v2 文档升级为 v3；该格式检查独立于当前代码 diff 是否产生事实或导航增量。
- 只要求判断或回答、未要求写文档时，结论为无需更新就不擅自升级或改写文件。
- 代码变化无需事实更新但交付物需要从 v1/v2 升级时，完成报告分别说明代码判定与格式迁移，不把迁移归因于该 diff。
- 首次 v3 升级允许结构性重写；完成升级后的更新必须优先按 `incremental-update.md` 局部修改。
- 已有 v3 文档没有事实或导航增量时保持原文，不借任务重写章节或刷新维护元数据。
- 不双写旧字段和 v3 字段，不记录阶段编号、提交列表或变更历史。

## 旧文档位置

历史根级模块文档位于：

```text
claudedocs/modules/*.md
```

## 迁移确认

monorepo 模式下，如果发现旧文档能映射到 owner，先输出迁移计划并等待用户确认。用户确认后才允许移动文件。

文档位置迁移与格式升级是两件事：用户只要求更新内容时，不擅自移动文件；用户只确认移动位置时，也要根据任务范围判断是否同时升级格式。

迁移计划格式：

```text
发现旧文档：
- claudedocs/modules/ConfigManageRouteCachedPage.md
  建议迁移到 apps/config-manage-system/claudedocs/modules/ConfigManageRouteCachedPage.md
```

## 迁移后更新

用户确认迁移后，同步更新：

- owner `claudedocs/README.md`
- 根 `AGENTS.md`
- 被迁移文档中的相对链接
- 其他已知引用旧路径的位置

迁移完成后搜索旧路径引用，确认没有遗漏。

## 无法判断 owner

无法可靠判断 owner 时，只输出候选和原因，不移动文件。要求用户指定 `apps/{name}`、`packages/{name}` 或 `libs/{name}` 后再继续。
