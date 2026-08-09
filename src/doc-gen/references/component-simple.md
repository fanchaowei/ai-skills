# 简单 Vue 组件补充规则

使用通用 v3 骨架，正文保持短而可跳读。没有可靠链路时不生成 Mermaid 或诊断章节。

## Vue 公开契约

### Props

{{PROPS_OR_NONE}}

### Emits

{{EMITS_OR_NONE}}

### Slots

{{SLOTS_OR_NONE}}

### Expose

{{EXPOSE_OR_NONE}}

四类接口必须全部扫描并显式出现；没有公开项时写“无”。普通 export、内部类型、store、adapter 或其他可导出内容不属于 Vue 公开契约。
