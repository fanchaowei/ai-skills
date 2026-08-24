---
doc_type: ai-module-spec
module_name: SampleFeature
owner: apps/sample-system
summary: 示例模块摘要
feature_index:
  sample_feature:
    entry: apps/sample-system/src/sample-feature.ts#useSampleFeature
    body_section: 示例功能
---

# SampleFeature

## 示例功能

`useSampleFeature` 为页面提供可取消的示例数据加载，并确保过期请求不会覆盖当前状态。

## 公开契约

- `useSampleFeature(featureId: Ref<string>)` 返回 `data`、`loading`、`error` 与 `reload`。
- `reload()` 会取消同一实例的在途请求，再为当前 `featureId` 创建新请求。
- 空标识不会发起请求，并会将数据恢复为空状态。

## 文件与符号

- `apps/sample-system/src/sample-feature.ts#useSampleFeature`：组合式入口。
- `apps/sample-system/src/sample-feature-request.ts#loadSampleFeature`：请求实现。
- `apps/sample-system/src/sample-feature-types.ts#SampleFeatureData`：返回数据类型。

## 验证

- `apps/sample-system/src/__test__/sample-feature.spec.ts` 验证取消旧请求与保留最新结果。
- `apps/sample-system/src/__test__/sample-feature-errors.spec.ts` 验证永久错误不会自动重试。

## 风险

- 移除取消逻辑会使慢请求覆盖新工作区的数据。
- 将空标识视为有效请求会产生无意义流量和错误提示。
