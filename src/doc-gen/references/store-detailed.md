# 详细 Pinia Store 补充规则

适用于包含复杂 action、副作用、请求依赖或跨状态联动的 store。按功能域记录状态变化、错误责任和验证入口，必要时生成状态矩阵。

## 当前公开契约

### State

{{STATE_OR_NONE}}

### Getters

{{GETTERS_OR_NONE}}

### Actions

{{ACTIONS_OR_NONE}}

只记录真实公共 state、getters 和 actions；跨模块消费者始终排除。
