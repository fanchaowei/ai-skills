# doc-gen v3 基线结果

## 运行信息

- skill 版本：当前工作树修改前的 `src/doc-gen`，Git revision `5e5161b`。
- 输入：`sample/FisheryMap.md`；当前 `src/doc-gen/evals/evals.json` 仅作历史迁移材料。
- 记录要求：只记录实际输出、路径和原文摘录，不预写预期修复。

## 场景 1：模块边界

- `sample/FisheryMap.md:33` 的 `key_files` 收录 `apps/fishery-guardian-system/src/layout/layout-content/index.vue`，理由为图层页签 checkbox、结果状态读取和失败回退。
- 同一调用方还出现在修改前必读、相关文件、依赖关系、影响范围、修改指南、核心流程与排查路径中。
- 样例把模块调用方的工具栏、checkbox 状态与回退实现作为 FisheryMap 文档事实记录。
- v2 fixture 运行 `20260808-102543-5e5161b/boundary-generation-red` 的 YAML 把 `apps/harbor-system/src/pages/HarborPage.vue` 放入 `key_files`；正文继续生成“下游消费者”“影响范围”“修改指南”和包含页面 checkbox 的排查步骤。
- 运行结果虽然把 HarborPage 标成模块外调用方，仍记录其状态消费、失败回退和修改要求，说明“标记为外部”没有阻止 caller 事实进入模块文档。

## 场景 2：核心功能定位

- 当前样例使用 `primary_use_cases`、`key_files` 和章节级 `detail_sections`，没有从电子围栏、历史轨迹等功能域直接指向真实 `路径#symbol` 的索引。
- 历史轨迹和电子围栏的入口、转换、状态与验证信息分散在“当前实现契约”“核心流程”“修改指南”“问题排查路径”等章节。
- v2 fixture 输出没有 `feature_index`；电子围栏入口只通过自创 `detail_sections.fence_entry` 指向整章，未提供仓库根相对 `HarborMap.vue#setZonesVisible` 导航。

## 场景 3：Bug 第一检查点

- 当前 YAML 没有症状索引或第一检查点入口。
- 正文排查路径包含模块调用方 checkbox 状态，并将调用方实现纳入排查步骤。
- v2 fixture 输出的“复选框勾选后没有围栏”首先检查 `HarborPage.vue`，并在多个症状中分析调用方回退；调用方再次污染模块内故障边界。

## 场景 4：数据与直接依赖契约变化

- “依赖关系”同时记录模块内部 adapter、API wrapper、直接公共依赖、调用方和 `@shared/ui/useElectronicFences` 内部能力，依赖角色没有分开。
- 数据转换事实分散在功能规则和依赖说明中，没有形成 DTO、API wrapper、adapter、公共模型与 Vue 结果的责任链。
- v2 fixture 输出能识别 API、adapter 与 MapCanvas 公共契约，但仍把页面消费影响与共享包变更规划混入目标模块的影响范围，没有形成仅限模块内部吸收位置的稳定边界。

## 场景 5：模块内事实冲突

- 尚未执行自包含冲突 fixture；当前样例未提供可独立复现的模块内冲突输入。

## 场景 6：已有文档增量更新

- 当前 skill 只规定旧文档升级到 v2 key，没有代码变化到受影响索引和正文小节的映射规则。
- 当前样例混合阶段编号、实现提交和历史执行记录，无法仅依据稳定当前事实判断最小更新范围。

## 场景 7：无需更新判定

- 当前 skill 没有内部重构或恢复既有契约时可不修改模块文档的判定规则。

## 基线失败模式汇总

- 当前三个历史 eval 的 `files` 数量均为 0；其中两个 prompt 指向的仓库路径不存在。历史 eval 不可执行，不构成 RED 证据。
- 样例包含 `primary_use_cases`、`key_files`、`top_risks` 和 `verification` 对象等 v2 导航结构。
- 样例记录调用方实现、阶段 4/4.5/4.7、历史提交、测试通过数量、环境阻断与人工未执行状态。
- 当前基线没有自包含代码 fixture；真实 Skill 行为 RED 证据将在 HarborMap 隔离场景运行后追加。
- 首次隔离运行 `20260808-101657-5e5161b/boundary-generation-red` 未产出完整回答并被中断，状态记录为 `not_run`，不作为语义 RED 证据。
- 第二次隔离运行 `20260808-102543-5e5161b/boundary-generation-red` 完成并形成可审计 RED：462 行 v2 文档保留 `primary_use_cases`、`key_files`、`read_order`、`top_risks`、`verification.commands`，自创 `detail_sections.fence_entry`，没有 `feature_index`，并把 caller 事实写入 YAML 与多处正文。

## GREEN 与合理化收敛

### 首批 GREEN：`20260808-110659-green-5e5161b`

- `boundary-generation` 结构与语义通过。
- `ui-state-bug`、`dto-contract-change` 的语义方向正确，但把 `feature_index` 生成为 sequence/list，结构失败；原始产物、结构日志和断言均保留在对应唯一场景目录。
- 合理化修正：模板与质量规则明确 stable snake_case mapping，validator 对 block/flow sequence 输出唯一专用错误，新增 PowerShell 回归 fixture 与测试。

### 中间 GREEN：`20260808-114526-5e5161b`

- mapping 修正后，`boundary-generation`、`ui-state-bug`、`dto-contract-change` 均通过。
- `quick-understanding` 首次输出写入“本次任务已执行通过”，语义失败；随后模板和质量规则禁止所有自然语言瞬时状态同义表达。
- `add-feature` 暴露出结构校验必须在独立副本中物化场景 diff；runbook 已改为 `git apply --check` 后 apply，并记录真实 validation root。
- `add-feature`、`modify-feature` 在 materialized root 上通过。

### 最终全量：`20260808-124651-5e5161b`

- 13 个 manifest 场景全部由独立临时工作区和 `fork_turns: none` 的新鲜执行者运行。
- 通过 12 个：`boundary-generation`、`quick-understanding`、`add-feature`、`modify-feature`、`remove-feature`、`ui-state-bug`、`concurrency-bug`、`dto-contract-change`、`provider-contract-change`、`fact-conflict`、`incremental-update`、`no-update-bugfix`。
- `no-update-refactor` 正确判断代码事实无需更新，但原样保留 v2 fixture 文档，结构失败；该 RED 促使 no-update 判定与 v1/v2 格式迁移解耦，并在顶层 Skill 流程落实纯判断、v1/v2 完整交付迁移、v3 字节保持三路分支。

### 最终针对性回归：`20260808-151056-5e5161b`

- `no-update-refactor`：通过；代码事实与导航无需更新，完整交付单独执行 v2→v3 迁移，私有函数未进入功能索引。
- `no-update-bugfix`：通过；恢复既有 last-call-wins 契约，格式迁移与代码判定分开报告。
- `boundary-generation`：通过；确认 no-update 分流没有影响普通首次生成。

### 当前最终 revision 全量回归：`20260808-163155-5e5161b`

- 本轮在最终规则、manifest、runbook 和结构校验器修订完成后重新执行全部 13 个 manifest 场景，没有拼接旧 run 的通过结果。
- 统一 Skill 快照为 `working-tree-sha256:3acad42ccd1e0a74cdf5c82721c7762f1b0af184cbd32bb7278e433018277b48`；每个场景的 `inputs.json` 保存 22 个运行时文件的逐文件 SHA-256 和同一整体 hash。
- 13 个场景全部通过：`boundary-generation`、`quick-understanding`、`add-feature`、`modify-feature`、`remove-feature`、`ui-state-bug`、`concurrency-bug`、`dto-contract-change`、`provider-contract-change`、`fact-conflict`、`incremental-update`、`no-update-bugfix`、`no-update-refactor`。
- `no-update-bugfix` 与 `no-update-refactor` 使用 `decision-only`，结果目录只包含 `generated/decision.md`，没有生成、迁移、复制或改写 `HarborMap.md`。
- `quick-understanding` 使用 `generate-then-read`：writer 先生成并通过结构检查，独立 reader 只接收 YAML、`电子围栏显隐编排` 和 `验证入口与证明范围`，其回答正确说明模块用途、`HarborMap.vue#setZonesVisible` 入口和最小验证范围。
- `incremental-update` 只使用 `modify-feature.diff`，将最低有效点数从 3 更新为 4，并补充 adapter 验证与事实冲突；模块边界、Vue 公开契约和直接公共依赖保持原文。
- 所有 diff 场景记录 diff 绝对路径、SHA-256、`git apply --check` 与 `git apply` 退出码；生成文档场景记录实际绝对结构验证根。
- 唯一持久证据根：`evals/doc-gen/results/20260808-163155-5e5161b/`。每个场景均有 `prompt.md`、`inputs.json`、`raw-response.md`、一个 `generated` 产物、`run.log`、`structure-check.log`、`assertions.json`。
- 独立终审后收紧 validator 顶层 schema：只允许模板定义的 14 个顶层字段，并强制这些字段全部存在；新增“未知顶层字段”和“缺失必需字段”拒绝回归，路径逃逸用例也保持通过。
- Skill 运行时文件未变化，整体 hash 仍为 `3acad42ccd1e0a74cdf5c82721c7762f1b0af184cbd32bb7278e433018277b48`。因此没有重新生成 Agent 原始产物，而是使用 SHA-256 为 `96e6474c51de0e14c7f14df1490a17e8fa0868a561a4c893d0f8626a35550544` 的新 validator，对同一 run 的 11 个不可变模块文档逐场景重新物化 diff 并全量复验，同时重新核对 2 个 decision-only 场景；结果 13/13 通过。
- validator-only 补充证据：`evals/doc-gen/results/20260808-163155-5e5161b/validator-revalidation.json` 和 `validator-revalidation.log`，记录 validator 路径/hash、绝对验证根、diff 元数据、退出码与 decision-only 文档缺失检查。
- 临时工作区清理状态：7 个场景为 `complete`；`fact-conflict`、`incremental-update`、`no-update-bugfix`、`no-update-refactor`、`provider-contract-change`、`quick-understanding` 为 `pending`。此前精确目录清理审批被拒，持久证据不受影响。

## 最终覆盖结论

- 当前最终 revision 的 13 个场景均有实际执行证据，并在同一全量 run 中 13/13 通过；旧 run 只保留为合理化和规则收敛历史，不参与最终通过结论。
- UI/状态 Bug、数据/并发 Bug、DTO 变化、provider 变化各有独立结果目录。
- 所有最终通过场景均有七项持久产物；`decision-only` 使用 `generated/decision.md`，其他场景使用 `generated/HarborMap.md`。
- 13 个场景使用同一 Skill 快照；前向执行未复用其他 run/scenario 输出。
- 后审 validator-only 全量复验已单独持久化，未覆盖原始场景日志，也未将其表述为新的 fresh-agent full run。
- 当前未完成项仅为 6 个精确临时评测目录的清理记录；`quick_validate.py` 按用户要求因环境配置缺失未运行，不计入本次验证结论。
