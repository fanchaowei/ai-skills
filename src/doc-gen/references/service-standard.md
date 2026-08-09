# Service/API 模块补充规则

使用通用 v3 骨架，按稳定服务能力组织入口、输入输出、错误语义和验证范围。

## 当前公开契约

### Public API

{{PUBLIC_API_OR_NONE}}

### 请求实例

{{REQUEST_INSTANCES_OR_NONE}}

### Context Provider

{{CONTEXT_PROVIDER_OR_NONE}}

### 输入输出

{{INPUT_OUTPUTS_OR_NONE}}

### 副作用

{{SIDE_EFFECTS_OR_NONE}}

provider 只记录公开声明和目标模块真实使用的最小契约，不复制内部实现或调用方逻辑。
