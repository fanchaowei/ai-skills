# 简单 Pinia Store 补充规则

使用通用 v3 骨架，围绕稳定状态能力组织功能目录。

## 当前公开契约

### State

{{STATE_OR_NONE}}

### Getters

{{GETTERS_OR_NONE}}

### Actions

{{ACTIONS_OR_NONE}}

只记录调用者可用的当前 state、getters 和 actions。私有 helper、内部缓存和调用方消费状态不进入公开契约。
