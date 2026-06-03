# 仓库路由规则

## 模式识别

优先根据用户说明判断仓库模式；用户没有说明时自动识别。

monorepo 信号：

- `pnpm-workspace.yaml`
- `turbo.json`
- `nx.json`
- `workspace.json`
- `project.json`
- 根 `package.json` 的 `workspaces`
- `apps/`
- `packages/`
- `libs/`

用户说明优先于自动识别，例如“按单项目模式生成”“这是 monorepo 项目”“这个模块属于 libs/shared-ui”。

## Owner 规则

| 路径模式 | 类型 | 根索引分类 |
| --- | --- | --- |
| `apps/{name}/...` | 应用 | `### 应用` |
| `packages/{name}/...` | 共享库 | `### 共享库` |
| `libs/{name}/...` | 共享库 | `### 共享库` |

如果仓库是 monorepo，但模块路径无法映射到 `apps/`、`packages/`、`libs/`，要求用户指定 owner，不猜测输出路径。

## 输出路径

monorepo：

```text
{owner}/claudedocs/modules/{ModuleName}.md
{owner}/claudedocs/README.md
```

非 monorepo：

```text
claudedocs/modules/{ModuleName}.md
```

所有路径都使用相对仓库根目录的正斜杠路径。
