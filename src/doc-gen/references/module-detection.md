# 模块识别规则

## 模块边界

- 文件路径输入：主文件就是该文件。
- 目录路径输入：优先选择同名 `.vue`、`index.vue`、`index.ts`、`index.tsx`、`index.js`。
- 扫描同级或子级 `components/`、`composables/`、`hooks/`、`utils/`、`helpers/`、`types/`、`scss/`。
- 排除 `node_modules/`、`.git/`、`dist/`、`build/`、`coverage/`。
- 识别结果不明确时，列出候选主文件和相关文件，让用户确认后继续。

## 模块类型

| 类型 | 识别信号 |
| --- | --- |
| `complex-module` | 文件数大于 5，或同时包含 Vue、TS、样式、hooks/utils |
| `component` | 主文件是 `.vue` 且位于 `components/` |
| `store` | 路径包含 `store/` 或代码包含 `defineStore` |
| `composable` | 路径包含 `composables/` 或 `hooks/`，文件名以 `use` 开头 |
| `utility` | 路径包含 `utils/` 或 `helpers/`，导出函数或常量 |
| `view` | 路径包含 `views/` 且主文件是 `.vue` |

识别优先级：`complex-module` > `component` > `store` > `composable` > `utility` > `view`。如果多个类型同时命中，优先选择更具体、更能描述修改入口的类型。

## 复杂度

- `simple`：单文件且少于 200 行。
- `medium`：1-3 个文件或 200-500 行。
- `complex`：超过 3 个文件、超过 500 行、或包含复杂状态/API/缓存/动态导入。

无法自动判断复杂度时，按 `medium` 处理，并在输出中说明判断依据。
