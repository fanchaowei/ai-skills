# 标准 Vue 组件补充规则

适用于包含局部状态、子组件协作或明确事件流的组件。使用通用 v3 骨架，按核心功能域记录入口、状态、公开结果和验证入口。

## Vue 公开契约

### Props

{{PROPS_OR_NONE}}

### Emits

{{EMITS_OR_NONE}}

### Slots

{{SLOTS_OR_NONE}}

### Expose

{{EXPOSE_OR_NONE}}

四类接口必须全部扫描并显式出现；没有公开项时写“无”。内部导出和调用方消费方式不得扩展公开契约范围。
