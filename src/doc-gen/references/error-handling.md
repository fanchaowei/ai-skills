# 错误处理规则

## 模块路径不存在

提示路径不存在，并要求用户检查路径。

## 无法识别模块类型

列出候选类型，让用户选择：

- `complex-module`
- `component`
- `store`
- `composable`
- `utility`
- `view`

## 无法识别 owner

在 monorepo 模式下要求用户指定 `apps/{name}`、`packages/{name}` 或 `libs/{name}`。

## 无法读取文件

提示无法读取的文件路径，并继续处理其他可读取文件。若主文件无法读取，停止执行。

## 索引更新失败

保留已生成模块文档，输出需要手动添加的索引条目。
