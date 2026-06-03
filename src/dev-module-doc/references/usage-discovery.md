# Usage Discovery

## 目标

生成文档前主动搜索真实使用方，确保使用示例和使用场景基于代码事实。

## 搜索策略

优先使用 `rg`。

搜索内容：

- 模块文件名。
- 导出的函数、类型、常量、组件名。
- import 路径。
- store id。
- composable 函数名。
- service 方法名。

## 示例命令

```powershell
rg "useManageWorkspaceStore" apps packages src
rg "serviceApiRegistry|registerServiceApi" apps packages src
rg "from ['\"].*service-api-registry" apps packages src
```

## 结果使用

- 找到真实使用方时，优先从真实调用中整理最小示例。
- 没有找到使用方时，基于公开导出生成最小示例，并说明当前仓库未搜索到明确使用方。
- 使用方与导出契约冲突时，以代码导出为准，并在注意事项中说明冲突。
