# 视图页面补充规则

适用于路由级 Vue 页面。使用通用 v3 骨架，按页面拥有的功能域记录路由入口、状态、API 与子组件协作。

## 当前公开契约

### 路由信息

{{ROUTE_INFO_OR_NONE}}

### 页面状态

{{PAGE_STATE_OR_NONE}}

### API 调用

{{API_CALLS_OR_NONE}}

### 子组件

{{CHILD_COMPONENTS_OR_NONE}}

子组件只记录当前 view 拥有或直接使用的公开边界，不沿调用方向扩展，也不复制子组件内部实现。
