# 历史文档迁移策略

## 旧文档位置

历史根级模块文档位于：

```text
claudedocs/modules/*.md
```

## 迁移确认

monorepo 模式下，如果发现旧文档能映射到 owner，先输出迁移计划并等待用户确认。用户确认后才允许移动文件。

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
