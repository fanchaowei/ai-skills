# Repository Routing

## 目标

根据用户指定模块路径判断开发使用文档的写入位置。

## Monorepo

当模块路径位于以下目录时，认为是 monorepo owner：

- `apps/<app-name>/`
- `packages/<package-name>/`

文档写入：

- `apps/<app-name>/docs/modules/<模块名>.md`
- `packages/<package-name>/docs/modules/<模块名>.md`

索引写入：

- `apps/<app-name>/docs/README.md`
- `packages/<package-name>/docs/README.md`

## 非 Monorepo

当模块路径不位于 `apps/*` 或 `packages/*`，且项目没有明确 monorepo owner 时，文档写入项目根：

- `docs/modules/<模块名>.md`
- `docs/README.md`

## 模块名生成

`docs/modules/*.md` 的 `<模块名>` 必须使用简体中文。根据文件名、目录名、业务上下文、路由名称或导出对象推断中文模块名，不直接沿用英文 slug、camelCase 或 PascalCase。技术缩写可保留常见写法，例如 API、HTTP、URL。

- `service-api-registry.ts` -> `服务接口注册表.md`
- `useManageWorkspaceStore.ts` -> `配置管理工作区状态模块.md`
- `manage-workspace-multi-backend-context.ts` -> `配置管理多上下文后端注入模块.md`
- `index.vue` 位于具名目录时，使用目录名。
- `index.vue` 位于页面根目录且目录名不清晰时，结合路由或父目录生成名称。
- 中文文件名应简洁表达模块职责，优先使用业务含义，不要机械逐词翻译。
- 文档一级标题使用同一个中文模块名。

## 冲突处理

如果无法判断 owner 或中文模块名，列出候选路径或候选中文名称并询问用户确认。
