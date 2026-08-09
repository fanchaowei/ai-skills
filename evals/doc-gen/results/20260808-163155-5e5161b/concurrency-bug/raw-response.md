# 执行报告

## 交付物

- 完整模块文档：`output/HarborMap.md`
- 完整执行报告：`output/raw-response.md`
- fixture：只读分析，未修改 `fixture/baseline`
- 索引：未写入。用户指定交付落点为 `output`，且要求不修改 fixture；因此未维护 `apps/harbor-system/claudedocs/README.md`。

## 输入与规则读取

- 完整读取 `skill/SKILL.md`。
- 按已有 v2 文档、详细 Vue 组件和诊断任务路由，读取：
  - `skill/references/repository-routing.md`
  - `skill/references/module-detection.md`
  - `skill/references/fact-model.md`
  - `skill/references/incremental-update.md`
  - `skill/references/migration-policy.md`
  - `skill/references/ai-module-spec-template.md`
  - `skill/references/component-detailed.md`
  - `skill/references/output-quality.md`

## 模块判定

- 仓库模式：monorepo，路径同时包含 `apps/` 与 `packages/`。
- owner：`apps/harbor-system`。
- 模块类型：Vue component。
- 文档深度：detailed。模块包含组件、类型、adapter、service、模块测试与跨 owner 公开依赖，并具有异步状态、错误映射和并发淘汰语义。
- 源文档：`fixture/baseline/apps/harbor-system/claudedocs/modules/HarborMap.md`，格式为 ai-module-spec v2。
- 输出处理：任务要求完整文档，因此将副本结构迁移为 v3；没有改写或移动 fixture 源文档。

## 边界确认

| 路径 | 角色 | 依据 |
| --- | --- | --- |
| `apps/harbor-system/src/components/harbor-map/HarborMap.vue` | owned | 主入口，拥有公开组件契约和异步编排 |
| `apps/harbor-system/src/components/harbor-map/types.ts` | owned | 被主入口和内部 adapter 使用，定义专属 DTO 与 Expose 结果 |
| `apps/harbor-system/src/components/harbor-map/adapters/normalize-zone.ts` | owned | 主入口真实 import，执行专属 DTO 转换 |
| `apps/harbor-system/src/components/harbor-map/services/harbor-api.ts` | owned | 主入口真实 import，定义专属读取入口 |
| `apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts` | owned verification | 模块内部测试，只用于预期和覆盖范围 |
| `packages/shared-ui/src/map-canvas/public.ts` | direct-public-dependency | 主入口和 adapter 真实引用公开类型/Expose |
| `apps/harbor-system/src/pages/HarborPage.vue` | caller | 调用方向指向 HarborMap，无条件排除；未读取其实现 |

边界证据充分，无需用户确认。旧文档把 caller 的 checkbox 回退写成模块事实，输出中已删除；旧文档遗漏的 `toolbar` slot 已从当前组件代码补全；旧文档的 `passed` 瞬时状态已删除。

## 核心功能域

1. `zone_visibility`：`HarborMap.vue#setZonesVisible` 的显示/隐藏编排。
2. `request_supersession`：共享 `requestVersion` 的过期调用识别和副作用边界。
3. `zone_normalization`：`normalize-zone.ts#normalizeZone` 的 DTO 过滤与坐标转换。
4. `harbor_zone_fetch`：`harbor-api.ts#fetchHarborZones` 的响应契约和当前入口实现。

## 数据/并发 Bug 定位

### 第一检查点

`HarborMap.vue#setZonesVisible` 中，读取完成后的版本检查与 `mapCanvas.replaceZones(zones)` 调用之间。若旧调用已经通过前置检查并进入共享画布，新调用无法通过递增 `requestVersion` 阻止该旧写入继续执行。

### 稳定信号

- 后置版本检查会让旧调用返回 `{ status: 'superseded' }`。
- 该旧调用不会在后置检查之后发出 `visible` 或映射 resolved 画布错误。
- `superseded` 只证明组件发现返回已过期，不证明共享画布没有被旧异步写入最后覆盖。
- 当前依赖契约不提供请求 id、取消、串行保证或最终画布状态，因此 `HarborZoneResult` 不是最终视觉数据的稳定信号。

### 故障边界

- `HarborMap` 拥有：调用版本、何时进入 `replaceZones()`、返回值与事件映射。
- `MapCanvas` 拥有：`replaceZones()`/`clearZones()` 的实际异步副作用。
- 两次替换都已进入 provider 后，当前模块只能抑制旧调用的后续组件行为，不能取消或回滚旧副作用。
- 另一个并发边界是隐藏 catch：过期的 `clearZones()` 拒绝仍会发出 `error`，因为该 catch 没有版本检查。

### 下一验证入口

`apps/harbor-system/src/components/harbor-map/__tests__/HarborMap.spec.ts`。

应覆盖以下稳定交错：

1. 旧显示调用先完成读取并进入第一个 deferred `replaceZones()`。
2. 新显示调用随后进入第二个 `replaceZones()`。
3. 新替换先完成，旧替换最后完成。
4. 测试桩在每次替换完成时记录代表最终画布数据的 zone id。
5. 同时观察最终记录、两个 `HarborZoneResult` 与 `zoneStatusChange`。

现有并发用例只让新读取先完成，旧读取在读取后的版本检查处被淘汰，因此 `replaceZones()` 只调用一次；它没有覆盖两个渲染副作用重叠的窗口。若修复要求 provider 提供取消、请求标识、串行化或最终状态读取，还需进入 `packages/shared-ui/src/map-canvas/public.ts` 对应的公开契约和跨 owner 集成验证。

## 当前事实限制

- `fetchHarborZones()` 当前固定返回成功空数组，所以不经 mock 的 fixture 路径不会进入 `replaceZones()`。模块测试通过 mock 构造非空和延迟响应；这能定义组件预期覆盖范围，但不代表当前服务实现会产生相同数据时序。
- `replaceZones()` resolved 返回 `empty` 时，组件返回 `empty` 同时发出 `error`；规范化为空时也返回 `empty`，但不发事件。
- 显示链路用一个宽 catch 包围读取、规范化和地图替换；最新调用中的 rejected `replaceZones()` 会被映射为 `request-error`，结构化结果不能区分读取拒绝与渲染拒绝。

## v2 到 v3 迁移说明

- 将 `spec_version` 升级为 `"3.0"`。
- 用 mapping 形式 `feature_index` 建立四个稳定功能导航。
- 补齐必需的 `scope`、`contract`、`verification`，并按事实加入 `risks`、`dependencies`、`diagnostics`、`data_flow`。
- 删除 v2 的 caller 污染、瞬时测试状态和旧字段。
- 完整扫描并记录 Props、Emits、Slots、Expose。
- 增加并发故障边界、结构化信号和稳定验证入口，不把第一检查点宣称为唯一根因。

## 自检

- YAML 使用 `doc_type: ai-module-spec` 与 `spec_version: "3.0"`。
- `feature_index` 为 mapping，4 项，均只有 `entry` 和 `body_section`。
- 所有代码路径使用仓库根相对正斜杠；symbol 来自当前源文件。
- 所有 `body_section` 均能定位到“功能目录”的真实标题。
- `detail_sections` 只使用固定词汇，且正文存在对应语义章节。
- Vue 公开契约四类全部扫描。
- caller、调用方回退、历史提交和瞬时验证状态未写入模块文档。
- 测试只用于预期和覆盖边界，没有被写成当前实现已符合预期或某次运行结论。
- 直接公共依赖只引用 `public.ts` 的最小公开声明，未读取 provider 内部实现。
- fixture 未修改。

## 未自动处理事项

- 未修改实现或测试；任务要求定位与文档交付，不授权修复代码。
- 未维护 fixture 内 owner 索引；交付要求禁止修改 fixture，且输出路径被明确覆盖到 `output`。
- 未执行测试；模块文档仅记录稳定验证入口与证明范围，不记录瞬时执行状态。
