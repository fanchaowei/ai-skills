# Module Detection

## 支持范围

首期支持：

- Vue 组件。
- 页面模块。
- Pinia store。
- composable。
- service/API 模块。
- 工具函数模块。

## Vue 组件

识别特征：

- `.vue` 文件。
- `defineProps`、`defineEmits`、`defineExpose`。
- Vue 2.7 Composition API 的 `defineComponent`、`setup`、`props`、`emits`。

## 页面模块

识别特征：

- 位于 `views/`、`pages/`、`router` 关联目录。
- 被路由配置引用。
- 包含页面级布局、数据加载、业务交互。

## Pinia Store

识别特征：

- 使用 `defineStore`。
- 文件名以 `use` 开头或位于 `store/`、`stores/`。

## Composable

识别特征：

- 文件名以 `use` 开头。
- 导出函数内部使用 Vue reactivity API，例如 `ref`、`reactive`、`computed`、`watch`。

## Service/API

识别特征：

- 使用 request、axios、fetch、WebSocket 或 API registry。
- 导出请求方法、接口注册项、服务实例。

## 工具函数

识别特征：

- 导出纯函数、常量转换、格式化、校验、计算逻辑。
- 不直接承担 UI 渲染或状态管理职责。

## 不支持范围

首期不支持 Vuex，不支持 Vue 2 class-style component / decorator 写法。
