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

优先使用文件名或目录名：

- `service-api-registry.ts` -> `service-api-registry.md`
- `useManageWorkspaceStore.ts` -> `useManageWorkspaceStore.md`
- `index.vue` 位于具名目录时，使用目录名。
- `index.vue` 位于页面根目录且目录名不清晰时，结合路由或父目录生成名称。

## 冲突处理

如果无法判断 owner 或模块名，列出候选路径并询问用户确认。
