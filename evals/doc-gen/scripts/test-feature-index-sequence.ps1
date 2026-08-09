$ErrorActionPreference = 'Stop'

$scriptsRoot = $PSScriptRoot
$validator = Join-Path $scriptsRoot 'validate-structure.ps1'
$expected = 'feature_index must be a YAML mapping keyed by stable snake_case feature domains; sequence/list is forbidden'
$misleadingErrors = @(
  'feature_index entry/body_section count mismatch',
  'Missing feature_index'
)
$cases = @(
  @{
    Name = 'block sequence'
    Fixture = Join-Path $scriptsRoot 'fixtures/feature-index-sequence.md'
  },
  @{
    Name = 'flow sequence'
    Fixture = Join-Path $scriptsRoot 'fixtures/feature-index-flow-sequence.md'
  }
)

foreach ($case in $cases) {
  $output = & $validator -DocumentPath $case.Fixture 2>&1
  $exitCode = $LASTEXITCODE
  $outputText = $output -join [Environment]::NewLine

  if ($exitCode -eq 0) {
    throw "Expected the $($case.Name) feature_index fixture to fail validation"
  }

  $dedicatedErrorCount = [regex]::Matches($outputText, [regex]::Escape($expected)).Count
  if ($dedicatedErrorCount -ne 1) {
    throw "Expected exactly one dedicated feature_index sequence error for $($case.Name). Actual output:`n$outputText"
  }

  foreach ($misleadingError in $misleadingErrors) {
    if ($outputText -match [regex]::Escape($misleadingError)) {
      throw "Unexpected misleading error for $($case.Name): $misleadingError`nActual output:`n$outputText"
    }
  }

  Write-Output "PASS: $($case.Name) feature_index is rejected only with the dedicated mapping error"
}

exit 0
