# 模块文档更新判断

## 结论

无需修改模块文档。

## 核对范围

- 现有文档：`fixture/v3/HarborMap.md`，已是 `ai-module-spec v3`。
- 代码变化：`apps/harbor-system/src/components/harbor-map/HarborMap.vue#setZonesVisible` 的隐藏分支异常处理新增过期请求检查；当 `currentVersion !== requestVersion` 时返回 `{ status: 'superseded' }`，不再发送错误事件或返回 `render-error`。
- 导航范围：`feature_index.zone_visibility` 与 `feature_index.request_supersession` 的路径和 symbol 均未变化；正文功能入口、公开契约、直接公共依赖和验证入口仍然有效。

## 判断理由

该 Bug 修复使异常分支重新符合现有文档已记录的稳定契约：`requestVersion` 保证最后调用获胜，过期异步结果返回 `superseded`，且不发布过期状态。补丁没有引入新的稳定模块事实，也没有改变路径、symbol、Props、Emits、Slots、Expose、结果状态集合、依赖契约或验证入口，因此不存在事实或导航增量。

## 文件处理

不生成、迁移、复制或改写 `HarborMap` 模块文档。

## 阻塞

无。
