# 索引维护规则

## Monorepo 根 AGENTS.md

根 `AGENTS.md` 的“模块文档索引”只维护 owner 文档入口，不写模块级功能、技术、特性长摘要。

分类只包含：

- `### 应用`
- `### 共享库`

示例：

```markdown
## 模块文档索引

### 应用
- [config-manage-system](apps/config-manage-system/claudedocs/README.md)

### 共享库
- [shared-services](packages/shared-services/claudedocs/README.md)
- [shared-ui](libs/shared-ui/claudedocs/README.md)
```

如果 owner 入口已存在，只更新链接或分类位置，不重复添加。

## Owner README

owner `claudedocs/README.md` 维护模块中等摘要。

标题格式：

```markdown
# {owner-name} 模块文档
```

固定章节：

```markdown
## 模块索引
```

模块条目格式：

```markdown
- **[{ModuleName}](modules/{ModuleName}.md)** - {一句话描述}
  - **功能**: {核心功能，逗号分隔}
  - **技术**: {核心技术栈}
  - **最后更新**: {YYYY-MM-DD}
```

复杂模块可以额外包含：

```markdown
  - **特性**: {亮点特性，逗号分隔}
```

## 非 monorepo

非 monorepo 项目沿用根 `AGENTS.md` 的模块级索引。可以保留模块描述、功能、技术、特性和最后更新时间。
