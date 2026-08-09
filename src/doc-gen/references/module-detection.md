# 模块识别规则

## 模块边界

1. 先确定用户指定的主入口。文件输入以该文件为入口；目录输入优先检查同名 `.vue`、`index.vue`、`index.ts`、`index.tsx` 或 `index.js`，但入口名称不决定完整边界。
2. 从主入口沿真实 import、类型引用、样式引用和模块内部测试收集候选。排除 `node_modules/`、`.git/`、`dist/`、`build/` 和 `coverage/`。
3. 按 `fact-model.md` 为每个候选分配 `owned`、`direct-public-dependency`、`shared`、`caller` 或 `excluded` 角色。
4. 跨目录文件只有同时存在专属性和强实现耦合证据时才是 `owned`。目录位置、相似命名或搜索命中不能单独证明所有权。
5. 不沿调用方向向 `caller` 扩展；调用方始终排除，其实现、状态、测试和回退逻辑不得进入模块事实。
6. `owned` 与 `shared` 证据冲突、用户范围与依赖方向冲突，或目录内存在多个独立所有者时，输出候选边界并等待用户确认。确认前不得生成最终模块文档。

## 模块类型

| 类型 | 识别信号 |
| --- | --- |
| `complex-module` | 文件数大于 5，或同时包含 Vue、TS、样式、hooks/utils |
| `component` | 主文件是 `.vue` 且位于 `components/` |
| `store` | 路径包含 `store/` 或代码包含 `defineStore` |
| `service` | 路径包含 `services/`、`service/`、`api/`，或代码包含请求实例、API 工厂、context provider |
| `composable` | 路径包含 `composables/` 或 `hooks/`，文件名以 `use` 开头 |
| `utility` | 路径包含 `utils/` 或 `helpers/`，导出函数或常量 |
| `view` | 路径包含 `views/` 且主文件是 `.vue` |

识别优先级：`complex-module` > `component` > `store` > `service` > `composable` > `utility` > `view`。如果多个类型同时命中，优先选择更具体、更能描述公开契约的类型。

## 复杂度

- `simple`：单文件且少于 200 行。
- `medium`：1-3 个文件或 200-500 行。
- `complex`：超过 3 个文件、超过 500 行、或包含复杂状态/API/缓存/动态导入。

无法自动判断复杂度时，按 `medium` 处理，并说明判断依据。复杂度只决定类型模板粒度，不决定是否强制生成诊断、数据流、状态矩阵、删除边界或其他按需章节。
