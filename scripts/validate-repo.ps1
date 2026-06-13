param(
    [string]$LabelsPath = "src\OutboundTranslationMod\translations\labels.txt",
    [string]$LegacyLabelsPath = "src\OutboundTranslationMod\translations\labels-bg.txt",
    [string]$ReleaseConfigPath = "release\OutboundTranslationMod.cfg",
    [string]$ReleaseReadmePath = "release\README-Nexus.txt"
)

$ErrorActionPreference = "Stop"

function Fail {
    param([string]$Message)
    throw $Message
}

function Read-LabelMap {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        Fail "Missing labels file: $Path"
    }

    $keys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $duplicates = [System.Collections.Generic.List[string]]::new()
    $invalid = [System.Collections.Generic.List[string]]::new()
    $lineNumber = 0

    foreach ($line in [System.IO.File]::ReadLines((Resolve-Path -LiteralPath $Path), [System.Text.Encoding]::UTF8)) {
        $lineNumber++
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#") -or $trimmed.StartsWith("//")) {
            continue
        }

        $equals = $trimmed.IndexOf("=")
        if ($equals -le 0) {
            $invalid.Add("${Path}:${lineNumber}")
            continue
        }

        $key = $trimmed.Substring(0, $equals).Trim()
        if ($key.Length -eq 0 -or -not $keys.Add($key)) {
            $duplicates.Add("${Path}:${lineNumber}:${key}")
        }
    }

    [pscustomobject]@{
        Path = $Path
        Count = $keys.Count
        DuplicateKeys = $duplicates
        InvalidLines = $invalid
    }
}

$labels = Read-LabelMap -Path $LabelsPath
if ($labels.DuplicateKeys.Count -gt 0) {
    Fail "Duplicate translation keys:`n$($labels.DuplicateKeys -join "`n")"
}
if ($labels.InvalidLines.Count -gt 0) {
    Fail "Invalid label lines:`n$($labels.InvalidLines -join "`n")"
}

if (Test-Path -LiteralPath $LegacyLabelsPath) {
    $current = Get-Content -LiteralPath $LabelsPath -Raw -Encoding UTF8
    $legacy = Get-Content -LiteralPath $LegacyLabelsPath -Raw -Encoding UTF8
    if ($current -ne $legacy) {
        Fail "$LegacyLabelsPath is out of sync with $LabelsPath"
    }
}

if (-not (Test-Path -LiteralPath $ReleaseConfigPath)) {
    Fail "Missing release config: $ReleaseConfigPath"
}

$config = Get-Content -LiteralPath $ReleaseConfigPath -Raw -Encoding UTF8
$requiredConfig = @(
    "DumpTranslations = false",
    "EnableTranslationOverrides = true",
    "EnableGnomeNameOverrides = true",
    "EnableCompassDirectionOverrides = true",
    "LabelsFileName = labels.txt",
    "TargetLanguageName = Ukrainian",
    "OverrideAllLanguages = false",
    "AssumeTargetLanguageOnStartup = true",
    "DumpCompassDirectionCandidates = false"
)

foreach ($entry in $requiredConfig) {
    if (-not $config.Contains($entry)) {
        Fail "Release config is missing required setting: $entry"
    }
}

if (-not (Test-Path -LiteralPath $ReleaseReadmePath)) {
    Fail "Missing release readme: $ReleaseReadmePath"
}

$releaseReadme = Get-Content -LiteralPath $ReleaseReadmePath -Raw -Encoding UTF8
if (-not $releaseReadme.Contains("AssumeTargetLanguageOnStartup = true")) {
    Fail "Release readme must mention AssumeTargetLanguageOnStartup = true"
}
if (-not $releaseReadme.Contains("EnableCompassDirectionOverrides = true")) {
    Fail "Release readme must mention EnableCompassDirectionOverrides = true"
}

$forbiddenPathPatterns = @(
    "^\./?Dump/",
    "^\./?Raw/",
    "^\./?tools/",
    "^\./?data/",
    "translation-dump\.txt$"
)

$repoFiles = @()
$insideGitRepo = $false
try {
    git rev-parse --is-inside-work-tree *> $null
    $insideGitRepo = ($LASTEXITCODE -eq 0)
}
catch {
    $insideGitRepo = $false
}

if ($insideGitRepo) {
    $repoFiles = @(git ls-files | ForEach-Object { "./$($_.Replace("\", "/"))" })
}

foreach ($file in $repoFiles) {
    foreach ($pattern in $forbiddenPathPatterns) {
        if ($file -match $pattern) {
            Fail "Forbidden generated/game-derived file found in repository tree: $file"
        }
    }
}

[pscustomobject]@{
    Labels = $labels.Count
    ReleaseConfig = $ReleaseConfigPath
    Status = "OK"
}
