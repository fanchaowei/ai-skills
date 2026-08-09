$ErrorActionPreference = 'Stop'

$scriptsRoot = $PSScriptRoot
$validator = Join-Path $scriptsRoot 'validate-structure.ps1'

$cases = @(
  @{
    Name = 'invalid quoted YAML scalar'
    Fixture = Join-Path $scriptsRoot 'fixtures/invalid-yaml-scalar.md'
    Expected = 'Invalid YAML scalar for summary'
  },
  @{
    Name = 'non-snake-case feature key'
    Fixture = Join-Path $scriptsRoot 'fixtures/feature-index-invalid-key.md'
    Expected = 'feature_index key must be stable snake_case: ZoneVisibility'
  },
  @{
    Name = 'more than eight feature domains'
    Fixture = Join-Path $scriptsRoot 'fixtures/feature-index-too-many.md'
    Expected = 'feature_index must contain at most 8 feature domains; actual: 9'
  },
  @{
    Name = 'unsupported feature field'
    Fixture = Join-Path $scriptsRoot 'fixtures/feature-index-extra-field.md'
    Expected = 'Unsupported feature_index field for zone_visibility: description'
  },
  @{
    Name = 'unknown top-level field'
    Fixture = Join-Path $scriptsRoot 'fixtures/unknown-top-level-field.md'
    Expected = 'Unsupported top-level YAML key: extra_metadata'
  },
  @{
    Name = 'missing required top-level field'
    Fixture = Join-Path $scriptsRoot 'fixtures/missing-required-field.md'
    Expected = 'Missing required top-level YAML key: module_name'
  }
)

foreach ($case in $cases) {
  $output = & $validator -DocumentPath $case.Fixture 2>&1
  $exitCode = $LASTEXITCODE
  $outputText = $output -join [Environment]::NewLine

  if ($exitCode -eq 0) {
    throw "Expected $($case.Name) to fail validation"
  }
  if ($outputText -notmatch [regex]::Escape($case.Expected)) {
    throw "Expected error '$($case.Expected)' for $($case.Name). Actual output:`n$outputText"
  }

  Write-Output "PASS: $($case.Name) is rejected"
}

$tempParent = Join-Path ([System.IO.Path]::GetTempPath()) "doc-gen-validator-$([guid]::NewGuid().ToString('N'))"
$repositoryRoot = Join-Path $tempParent 'repository'
$escapeRoot = Join-Path $tempParent 'repository-escape'

try {
  New-Item -ItemType Directory -Path $repositoryRoot -Force | Out-Null
  New-Item -ItemType Directory -Path $escapeRoot -Force | Out-Null
  Set-Content -Encoding utf8 -LiteralPath (Join-Path $escapeRoot 'outside.ts') -Value 'export function outside() {}'

  $escapeDocument = Join-Path $tempParent 'path-escape.md'
  $escapeLines = @(
    '---',
    'doc_type: ai-module-spec',
    'spec_version: "3.0"',
    'module_name: Example',
    'module_type: component',
    'owner: apps/example',
    'audience: ai',
    'read_mode: progressive',
    'depth: standard',
    'summary: "Example module."',
    'feature_index:',
    '  outside:',
    '    entry: ../repository-escape/outside.ts#outside',
    '    body_section: Outside Feature',
    'detail_sections:',
    '  scope: Module Scope',
    '  contract: Public Contract',
    '  verification: Verification Scope',
    'status: active',
    'last_updated: "2026-08-09"',
    'last_updated_by: doc-gen',
    '---',
    '',
    '## Module Scope',
    '',
    'Example scope.',
    '',
    '## Feature Catalog',
    '',
    '### Outside Feature',
    '',
    'Example feature.',
    '',
    '## Public Contract',
    '',
    'Example contract.',
    '',
    '## Verification Scope',
    '',
    'Example verification entry.'
  )
  $escapeLines | Set-Content -Encoding utf8 -LiteralPath $escapeDocument

  $output = & $validator -DocumentPath $escapeDocument -RepositoryRoot $repositoryRoot 2>&1
  $exitCode = $LASTEXITCODE
  $outputText = $output -join [Environment]::NewLine
  $expected = 'Feature entry escapes repository root: ../repository-escape/outside.ts#outside'

  if ($exitCode -eq 0) {
    throw 'Expected repository path escape to fail validation'
  }
  if ($outputText -notmatch [regex]::Escape($expected)) {
    throw "Expected error '$expected'. Actual output:`n$outputText"
  }

  Write-Output 'PASS: repository path escape is rejected'
} finally {
  if (Test-Path -LiteralPath $tempParent) {
    Remove-Item -LiteralPath $tempParent -Recurse -Force
  }
}

exit 0
