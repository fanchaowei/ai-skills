---
doc_type: ai-module-spec
module_name: WorkspaceHost
owner: apps/sample-system
summary: 承载相互隔离的工作区页面与应用状态快照
feature_index:
  workspace_host:
    entry: apps/sample-system/src/workspace/WorkspaceHost.vue
    body_section: 工作区承载
---

# WorkspaceHost

## 工作区承载

`WorkspaceHost` 为每个已打开工作区维护独立页面树和应用状态快照。切换工作区时，它先保存当前快照，再恢复目标工作区的页面和选择状态。

## 公开契约

- `openWorkspace(workspaceId)` 创建或激活工作区。
- `closeWorkspace(workspaceId)` 释放对应页面树和本地状态。
- 页面缓存键必须包含 `workspaceId`，避免相同路由在不同工作区共享实例。

## 验证与风险

- 组件测试验证两个工作区同名页面具有独立表单状态。
- 若缓存键省略工作区标识，页面状态会跨工作区泄漏。
