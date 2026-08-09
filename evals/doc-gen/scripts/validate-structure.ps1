param(
  [Parameter(Mandatory = $true)]
  [string]$DocumentPath,

  [Parameter(Mandatory = $false)]
  [string]$RepositoryRoot
)

$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure([string]$message) {
  $failures.Add($message)
}

function Unquote([string]$value) {
  $trimmed = $value.Trim()
  if (($trimmed.StartsWith('"') -and $trimmed.EndsWith('"')) -or
      ($trimmed.StartsWith("'") -and $trimmed.EndsWith("'"))) {
    return $trimmed.Substring(1, $trimmed.Length - 2)
  }
  return $trimmed
}

function Test-YamlScalar([string]$value) {
  $trimmed = $value.Trim()
  if ($trimmed.Length -eq 0 -or $trimmed.Contains("`t")) {
    return $false
  }

  $startsDouble = $trimmed.StartsWith('"')
  $endsDouble = $trimmed.EndsWith('"')
  $startsSingle = $trimmed.StartsWith("'")
  $endsSingle = $trimmed.EndsWith("'")
  if ($startsDouble -or $endsDouble -or $startsSingle -or $endsSingle) {
    return ($trimmed.Length -ge 2) -and
      (($startsDouble -and $endsDouble) -or ($startsSingle -and $endsSingle))
  }

  if ($trimmed.StartsWith('[') -or $trimmed.StartsWith('{') -or $trimmed -match ':\s') {
    return $false
  }

  return $true
}

if (-not (Test-Path -LiteralPath $DocumentPath -PathType Leaf)) {
  Write-Error "Document does not exist: $DocumentPath"
  exit 1
}

$document = Get-Content -Raw -Encoding utf8 -LiteralPath $DocumentPath
if ($document -notmatch '(?s)\A---\r?\n(?<yaml>.*?)\r?\n---\r?\n(?<body>.*)\z') {
  Write-Error 'Document must start with one closed YAML frontmatter block'
  exit 1
}

$yaml = $Matches.yaml
$body = $Matches.body

$yamlLines = $yaml -split '\r?\n'
$topLevelValues = @{}
$topLevelKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$featureDomains = @{}
$detailValues = @{}
$currentSection = $null
$currentFeature = $null
$featureIndexPresent = $false
$detailSectionsPresent = $false
$featureIndexUsesSequence = $false
$allowedTopLevelKeys = @(
  'doc_type',
  'spec_version',
  'module_name',
  'module_type',
  'owner',
  'audience',
  'read_mode',
  'depth',
  'summary',
  'feature_index',
  'detail_sections',
  'status',
  'last_updated',
  'last_updated_by'
)
$requiredTopLevelKeys = $allowedTopLevelKeys

foreach ($line in $yamlLines) {
  if ($line.Trim().Length -eq 0 -or $line.TrimStart().StartsWith('#')) {
    continue
  }
  if ($line.Contains("`t")) {
    Add-Failure 'YAML indentation must use spaces, not tabs'
    continue
  }

  if ($line -match '^(?<key>[A-Za-z_][A-Za-z0-9_]*):(?<value>.*)$') {
    $key = $Matches.key
    $value = $Matches.value.Trim()
    if (-not $topLevelKeys.Add($key)) {
      Add-Failure "Duplicate top-level YAML key: $key"
    }
    if ($allowedTopLevelKeys -notcontains $key) {
      Add-Failure "Unsupported top-level YAML key: $key"
    }

    $currentFeature = $null
    if ($key -eq 'feature_index') {
      $featureIndexPresent = $true
      if ($value.StartsWith('[')) {
        $featureIndexUsesSequence = $true
        $currentSection = $null
      } elseif ($value.Length -ne 0) {
        Add-Failure 'feature_index must use a block YAML mapping'
        $currentSection = $null
      } else {
        $currentSection = 'feature_index'
      }
    } elseif ($key -eq 'detail_sections') {
      $detailSectionsPresent = $true
      if ($value.Length -ne 0) {
        Add-Failure 'detail_sections must use a block YAML mapping'
        $currentSection = $null
      } else {
        $currentSection = 'detail_sections'
      }
    } else {
      $currentSection = $null
      if (-not (Test-YamlScalar $value)) {
        Add-Failure "Invalid YAML scalar for $key"
      } else {
        $topLevelValues[$key] = Unquote $value
      }
    }
    continue
  }

  if ($currentSection -eq 'feature_index') {
    if ($line -match '^\s*-\s+') {
      $featureIndexUsesSequence = $true
      continue
    }
    if ($featureIndexUsesSequence) {
      continue
    }
    if ($line -match '^ {2}(?<key>[^:]+):\s*$') {
      $featureKey = $Matches.key.Trim()
      if ($featureKey -cnotmatch '^[a-z][a-z0-9]*(?:_[a-z0-9]+)*$') {
        Add-Failure "feature_index key must be stable snake_case: $featureKey"
      }
      if ($featureDomains.ContainsKey($featureKey)) {
        Add-Failure "Duplicate feature_index key: $featureKey"
      } else {
        $featureDomains[$featureKey] = @{}
      }
      $currentFeature = $featureKey
      continue
    }
    if ($line -match '^ {4}(?<key>[A-Za-z_][A-Za-z0-9_]*):\s*(?<value>.+?)\s*$') {
      $field = $Matches.key
      $value = $Matches.value
      if (-not $currentFeature) {
        Add-Failure "feature_index field appears before a feature domain: $field"
        continue
      }
      if (@('entry', 'body_section') -notcontains $field) {
        Add-Failure "Unsupported feature_index field for $($currentFeature): $field"
        continue
      }
      if ($featureDomains[$currentFeature].ContainsKey($field)) {
        Add-Failure "Duplicate feature_index field for $($currentFeature): $field"
        continue
      }
      if (-not (Test-YamlScalar $value)) {
        Add-Failure "Invalid YAML scalar for feature_index.$currentFeature.$field"
        continue
      }
      $featureDomains[$currentFeature][$field] = Unquote $value
      continue
    }

    Add-Failure "Invalid feature_index YAML line: $line"
    continue
  }

  if ($currentSection -eq 'detail_sections') {
    if ($line -match '^ {2}(?<key>[a-z_]+):\s*(?<value>.+?)\s*$') {
      $key = $Matches.key
      $value = $Matches.value
      if ($detailValues.ContainsKey($key)) {
        Add-Failure "Duplicate detail_sections key: $key"
      } elseif (-not (Test-YamlScalar $value)) {
        Add-Failure "Invalid YAML scalar for detail_sections.$key"
      } else {
        $detailValues[$key] = Unquote $value
      }
      continue
    }

    Add-Failure "Invalid detail_sections YAML line: $line"
    continue
  }

  Add-Failure "Unexpected YAML indentation or syntax: $line"
}

foreach ($requiredKey in $requiredTopLevelKeys) {
  if (-not $topLevelKeys.Contains($requiredKey)) {
    Add-Failure "Missing required top-level YAML key: $requiredKey"
  }
}

if (-not $topLevelValues.ContainsKey('doc_type') -or $topLevelValues.doc_type -ne 'ai-module-spec') {
  Add-Failure 'Missing doc_type: ai-module-spec'
}
if (-not $topLevelValues.ContainsKey('spec_version') -or $topLevelValues.spec_version -ne '3.0') {
  Add-Failure 'Missing spec_version: "3.0"'
}
if (-not $featureIndexPresent) {
  Add-Failure 'Missing feature_index'
}
if ($featureIndexUsesSequence) {
  Add-Failure 'feature_index must be a YAML mapping keyed by stable snake_case feature domains; sequence/list is forbidden'
}
if (-not $detailSectionsPresent) {
  Add-Failure 'Missing detail_sections'
}

$forbidden = @(
  'primary_use_cases',
  'entry_files',
  'key_files',
  'read_order',
  'risk_level',
  'top_risks'
)
foreach ($field in $forbidden) {
  if ($yaml -match "(?m)^$([regex]::Escape($field)):\s*") {
    Add-Failure "Forbidden v2 field: $field"
  }
}
if ($yaml -match '(?m)^verification:\s*$') {
  Add-Failure 'Forbidden v2 verification object; use detail_sections.verification'
}

$allowedDetailKeys = @('scope', 'contract', 'verification', 'risks', 'dependencies', 'diagnostics', 'data_flow', 'removal')
foreach ($required in @('scope', 'contract', 'verification')) {
  if (-not $detailValues.ContainsKey($required)) {
    Add-Failure "Missing detail_sections.$required"
  }
}
foreach ($key in $detailValues.Keys) {
  if ($allowedDetailKeys -notcontains $key) {
    Add-Failure "Unsupported detail_sections key: $key"
  }
  $heading = [regex]::Escape([string]$detailValues[$key])
  if ($body -notmatch "(?m)^##\s+$heading\s*$") {
    Add-Failure "Detail section is not reachable: $key -> $($detailValues[$key])"
  }
}

$featureEntries = [System.Collections.Generic.List[string]]::new()
$bodySections = [System.Collections.Generic.List[string]]::new()
if (-not $featureIndexUsesSequence) {
  if ($featureDomains.Count -gt 8) {
    Add-Failure "feature_index must contain at most 8 feature domains; actual: $($featureDomains.Count)"
  }
  foreach ($featureKey in $featureDomains.Keys) {
    foreach ($requiredField in @('entry', 'body_section')) {
      if (-not $featureDomains[$featureKey].ContainsKey($requiredField)) {
        Add-Failure "Missing feature_index.$featureKey.$requiredField"
      }
    }
    if ($featureDomains[$featureKey].ContainsKey('entry')) {
      $featureEntries.Add([string]$featureDomains[$featureKey].entry)
    }
    if ($featureDomains[$featureKey].ContainsKey('body_section')) {
      $bodySections.Add([string]$featureDomains[$featureKey].body_section)
    }
  }
}

foreach ($value in $bodySections) {
  $leaf = ($value -split '/')[-1]
  if ($body -notmatch "(?m)^#{2,4}\s+$([regex]::Escape($leaf))\s*$") {
    Add-Failure "Feature body_section is not reachable: $value"
  }
}

$resolvedRepositoryRoot = $null
if ($RepositoryRoot) {
  if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {
    Add-Failure "Repository root does not exist: $RepositoryRoot"
  } else {
    $resolvedRepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
  }
}

foreach ($entry in $featureEntries) {
  $parts = $entry -split '#', 2
  $relativePath = $parts[0]
  $symbol = if ($parts.Count -eq 2) { $parts[1] } else { $null }

  $pathSegments = $relativePath -split '/'
  if (@($pathSegments | Where-Object { $_ -eq '..' }).Count -gt 0) {
    Add-Failure "Feature entry escapes repository root: $entry"
    continue
  }
  if ([System.IO.Path]::IsPathRooted($relativePath) -or $relativePath.Contains('\') -or
      @($pathSegments | Where-Object { $_ -eq '.' -or $_ -eq '' }).Count -gt 0) {
    Add-Failure "Feature entry must use a repository-relative forward-slash path: $entry"
    continue
  }

  if ($resolvedRepositoryRoot) {
    $candidate = [System.IO.Path]::GetFullPath((Join-Path $resolvedRepositoryRoot ($relativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
    $rootBoundary = $resolvedRepositoryRoot.TrimEnd([char[]]@(
      [System.IO.Path]::DirectorySeparatorChar,
      [System.IO.Path]::AltDirectorySeparatorChar
    )) + [System.IO.Path]::DirectorySeparatorChar
    if (-not $candidate.StartsWith($rootBoundary, [System.StringComparison]::OrdinalIgnoreCase)) {
      Add-Failure "Feature entry escapes repository root: $entry"
      continue
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
      Add-Failure "Feature entry path does not exist: $relativePath"
      continue
    }
    if ($symbol) {
      $source = Get-Content -Raw -Encoding utf8 -LiteralPath $candidate
      if ($source -notmatch [regex]::Escape($symbol)) {
        Add-Failure "Feature entry symbol does not exist: $entry"
      }
    }
  }
}

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Output "FAIL: $_" }
  exit 1
}

Write-Output "PASS: $DocumentPath"
Write-Output "feature_entries=$($featureEntries.Count) detail_sections=$($detailValues.Count)"
exit 0
