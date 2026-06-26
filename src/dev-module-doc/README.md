# dev-module-doc

面向开发人员的模块开发使用文档生成 skill。

该 skill 与 `doc-gen` 分工不同：

- `doc-gen` 面向 AI，帮助 AI 理解模块上下文和演进。
- `dev-module-doc` 面向开发人员，帮助开发人员快速使用和修改模块。

默认输出：

- monorepo：`apps/<app>/docs/modules/` 或 `packages/<package>/docs/modules/`
- 非 monorepo：`docs/modules/`
- `docs/modules/*.md`：文件名和正文使用简体中文。

默认维护：

- `docs/README.md`
