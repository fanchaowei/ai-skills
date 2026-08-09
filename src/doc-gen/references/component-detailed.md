# 详细 Vue 组件补充规则

适用于组件组、复杂交互组件或公开接口较多的组件。使用通用 v3 骨架，并按需生成状态矩阵、数据流、诊断和删除边界。

## Vue 公开契约

### Props

{{PROPS_OR_NONE}}

### Emits

{{EMITS_OR_NONE}}

### Slots

{{SLOTS_OR_NONE}}

### Expose

{{EXPOSE_OR_NONE}}

四类接口必须全部扫描并显式出现；没有公开项时写“无”。只记录目标组件当前公开语义，不记录调用方状态或普通 export。
