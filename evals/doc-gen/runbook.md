# doc-gen 外部评测 runbook

## 定位

`evals/doc-gen/` 不属于 Skill 运行时目录，不会被 Codex 自动发现、加载或执行。开发者修改 `src/doc-gen` 时必须显式运行这里的场景；`src/doc-gen/SKILL.md` 不得引用本目录。

## RED、GREEN、REFACTOR

1. RED：修改 Skill 前，用自包含 fixture 运行场景并保存真实失败原文。
2. GREEN：使用同一 prompt 和原始 fixture，替换为修改后的 Skill 重新运行。
3. REFACTOR：记录新出现的合理化，补充最窄规则后先重跑失败场景，再使用修改后的同一份 Skill 执行全部 manifest 场景。不得用旧 Skill revision 的通过结果拼接最终 GREEN。

创建或修改 manifest、fixture 或断言不代表评测已执行。没有实际运行证据时状态为 `not_run`；该状态只存在于外部评测记录，不进入模块文档。

## 唯一运行目录

每次全量运行生成一个唯一 `run-id`，每个 manifest 场景使用稳定且唯一的 `scenario-id`：

```powershell
$runId = "$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(git rev-parse --short HEAD)"
$scenarioId = '<manifest id>'
$resultDir = Join-Path (Resolve-Path 'evals\doc-gen\results').Path "$runId\$scenarioId"
if (Test-Path -LiteralPath $resultDir) { throw "Result directory already exists: $resultDir" }
```

不得覆盖、复用或从其他 run/scenario 目录读取结果。

## 场景执行模式

manifest 支持三种执行模式：

- 默认生成/更新：一个新鲜 writer 接收 Skill、声明的 fixture 和 prompt，输出 `generated/HarborMap.md`。
- `decision-only`：一个新鲜执行者只判断是否需要更新。输出 `generated/decision.md`，且结果目录不得出现 `generated/HarborMap.md`；该场景不执行模块文档结构检查。
- `generate-then-read`：先由新鲜 writer 根据 Skill 和 fixture 生成 `generated/HarborMap.md`，再由另一个 `fork_turns: "none"` 的新鲜 reader 只读取 manifest 声明的 YAML 与正文摘录。reader 不接收 Skill、代码、完整文档、writer 原始回答或评分断言；`raw-response.md` 保存 reader 的完整回答。

## 新鲜执行者隔离

每个 writer、decision executor 和 reader 都使用独立临时工作区与 `fork_turns: "none"` 的新鲜 Agent/线程。writer 或 decision executor 只提供：

- manifest 中的用户 prompt。
- 当前 `src/doc-gen` Skill。
- 场景声明的原始 fixture 文件或 diff。

临时工作区不得包含设计文档、实施计划、审查清单、成功/阻断断言答案、`baseline-results.md`、历史结果或其他场景输出。

```powershell
$evalTemp = Join-Path ([System.IO.Path]::GetTempPath()) "doc-gen-eval-$runId-$scenarioId"
if (Test-Path -LiteralPath $evalTemp) { throw "Temp directory already exists: $evalTemp" }
New-Item -ItemType Directory -Path "$evalTemp\skill\references" -Force | Out-Null
New-Item -ItemType Directory -Path "$evalTemp\fixture" -Force | Out-Null
Copy-Item src\doc-gen\SKILL.md "$evalTemp\skill\SKILL.md"
Copy-Item src\doc-gen\references\* "$evalTemp\skill\references" -Recurse
```

只复制场景 `files` 声明的原始输入。不要复制整个 `evals/doc-gen`。`generate-then-read` 的 reader 临时工作区只包含从本场景新生成文档截取的允许片段和 reader prompt。

## Skill revision 与输入审计

运行前按仓库根相对路径排序 `src/doc-gen` 的全部运行时文件，记录每个文件的 SHA-256，并对该文件哈希清单再次计算整体 `skill_snapshot_sha256`。`inputs.json` 必须保存完整文件哈希清单；`skill_revision` 使用 `working-tree-sha256:<skill_snapshot_sha256>`，不得只写 HEAD 或自定义 `working-tree-final` 标签。

所有输入路径、writer/reader 临时工作区和结构验证根都记录当次运行的绝对路径。带 diff 场景同时记录 diff 的绝对路径、SHA-256、`git apply --check` 退出码和 `git apply` 退出码。描述性文字不能代替实际路径。

## 持久化原始产物

Agent 结束后，先创建唯一结果目录并持久保存以下文件，再清理临时工作区：

```text
results/<run-id>/<scenario-id>/
  prompt.md
  inputs.json
  raw-response.md
  generated/HarborMap.md 或 generated/decision.md
  run.log
  structure-check.log
  assertions.json
```

每个场景仍然持久化七项产物，但 `decision-only` 使用 `generated/decision.md` 替代 `generated/HarborMap.md`。`inputs.json` 至少记录 `run_id`、`scenario_id`、完整 Skill 文件哈希清单、整体 Skill hash、绝对输入路径、隔离策略、实际结构验证根或明确的 `document_expected: false`。`raw-response.md` 保存完整原始回答；不能只保存执行者的完成声明。

## 评分顺序

1. 确认所有原始产物已经持久保存。
2. 默认生成/更新和 `generate-then-read` 场景准备独立结构验证根。无 diff 场景可以直接使用原始 baseline；带 diff 场景必须在当前场景自己的 `$evalTemp` 下复制 baseline，并且只把该场景 manifest 声明的 diff 应用到副本。不得修改原始 fixture，也不得读取其他 run/scenario 的结果。`decision-only` 不生成模块文档，跳过结构验证并在 `structure-check.log` 记录 `document_expected=false` 与 `exit_code=0`。

以下示例默认 `$evalTemp`、`$resultDir` 已由当前场景创建。`$scenarioDiff` 在无 diff 场景保持 `$null`；带 diff 时只能赋值为当前 manifest `files` 中声明的 diff：

```powershell
$baselineRoot = (Resolve-Path -LiteralPath 'evals\doc-gen\fixtures\harbor-map\baseline').Path
$scenarioDiff = $null
# 带 diff 场景仅将下一行替换为当前 manifest 声明的那个 diff；不得扫描 changes 目录。
# $scenarioDiff = (Resolve-Path -LiteralPath 'evals\doc-gen\fixtures\harbor-map\changes\add-feature.diff').Path

if ($scenarioDiff) {
  $validationParent = Join-Path $evalTemp 'structure-validation'
  $validationRoot = Join-Path $validationParent 'repository'
  if (Test-Path -LiteralPath $validationRoot) { throw "Validation root already exists: $validationRoot" }
  New-Item -ItemType Directory -Path $validationParent -Force | Out-Null
  Copy-Item -LiteralPath $baselineRoot -Destination $validationRoot -Recurse

  $resolvedEvalTemp = (Resolve-Path -LiteralPath $evalTemp).Path.TrimEnd([System.IO.Path]::DirectorySeparatorChar)
  $resolvedValidationRoot = (Resolve-Path -LiteralPath $validationRoot).Path
  if (-not $resolvedValidationRoot.StartsWith(
      $resolvedEvalTemp + [System.IO.Path]::DirectorySeparatorChar,
      [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Validation root escaped current scenario temp: $resolvedValidationRoot"
  }

  Push-Location $resolvedValidationRoot
  try {
    git apply --check --whitespace=nowarn -- $scenarioDiff
    if ($LASTEXITCODE -ne 0) { throw "Diff check failed: $scenarioDiff" }
    git apply --whitespace=nowarn -- $scenarioDiff
    if ($LASTEXITCODE -ne 0) { throw "Diff apply failed: $scenarioDiff" }
  } finally {
    Pop-Location
  }
} else {
  $resolvedValidationRoot = $baselineRoot
}

$structureLog = Join-Path $resultDir 'structure-check.log'
"validation_repository_root=$resolvedValidationRoot" | Add-Content -Encoding utf8 (Join-Path $resultDir 'run.log')
"repository_root=$resolvedValidationRoot" | Set-Content -Encoding utf8 $structureLog

$previousErrorActionPreference = $ErrorActionPreference
try {
  $ErrorActionPreference = 'Continue'
  $structureOutput = powershell.exe -NoProfile -ExecutionPolicy Bypass -File evals\doc-gen\scripts\validate-structure.ps1 `
    -DocumentPath (Join-Path $resultDir 'generated\HarborMap.md') `
    -RepositoryRoot $resolvedValidationRoot 2>&1
  $structureExitCode = $LASTEXITCODE
} finally {
  $ErrorActionPreference = $previousErrorActionPreference
}
$structureOutput | ForEach-Object { $_.ToString() } | Add-Content -Encoding utf8 $structureLog
$structureOutput | Write-Output
if ($structureExitCode -ne 0) { throw 'Structure validation failed' }
```

3. 将实际绝对 `validation_repository_root` 写入 `inputs.json`，将同一绝对路径写入 `run.log`，并在 `structure-check.log` 首行记录该绝对路径后追加完整脚本输出。带 diff 场景记录的是本场景 materialized 副本，不是 `materialized diff` 等描述文本。`decision-only` 的三个位置统一记录 `document_expected=false`。
4. `generate-then-read` 在 writer 文档完成结构检查后，按 manifest 的 `reader_sections` 生成摘录并启动独立 reader；评分只使用 reader 原始回答，不使用 writer 上下文。
5. 人工核对 manifest 的任务成功断言与阻断断言，不根据执行者自评打分。`decision-only` 还必须确认结果目录没有 `generated/HarborMap.md`。
6. 将结构结果、语义结果、逐项证据和最终状态写入 `assertions.json`。
7. 在 `baseline-results.md` 只写跨运行摘要和唯一证据路径，不替代原始证据。

## 结果记录字段

每个结果至少包含：

- `run_id`、`scenario_id`、Skill revision。
- Skill 文件哈希清单、整体 SHA-256、实际绝对输入路径、读取范围和输出路径。
- 结构检查结果与日志路径。
- 带 diff 场景的 diff SHA-256、应用检查与应用退出码、实际绝对验证根。
- `generate-then-read` 的 writer 与 reader 独立临时工作区、reader 摘录范围和 reader 原始回答。
- 语义成功断言、阻断断言、原文证据和最终状态。
- 清理临时工作区的记录。

只有原始输出持久化、结构检查完成且人工断言核对结束后，才能记录 `pass` 或 `fail`。
