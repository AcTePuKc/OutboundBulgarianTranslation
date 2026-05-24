param(
    [string]$DumpDir = ".\Dump",
    [string]$OutputDir = ".\data\analysis"
)

$ErrorActionPreference = "Stop"

$resolvedDumpDir = [System.IO.Path]::GetFullPath($DumpDir)
$resolvedOutputDir = [System.IO.Path]::GetFullPath($OutputDir)
[System.IO.Directory]::CreateDirectory($resolvedOutputDir) | Out-Null

$files = Get-ChildItem $resolvedDumpDir -File

function Get-AssetStem {
    param([string]$BaseName)

    return ($BaseName `
        -replace '-sharedassets0\.assets-\d+$','' `
        -replace '-globalgamemanagers\.assets-\d+$','' `
        -replace '-unity default resources-\d+$','' `
        -replace '-unity_builtin_extra-\d+$','')
}

$summary = $files |
    Group-Object { Get-AssetStem $_.BaseName } |
    Sort-Object Count -Descending |
    Select-Object -First 500 Name, Count

$summary | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $resolvedOutputDir "asset-name-summary.csv")

$patterns = [ordered]@{
    "translate-components.txt" = '^Translate-sharedassets0\.assets-\d+\.txt$'
    "tmp-components.txt" = '^TextMeshProUGUI-sharedassets0\.assets-\d+\.txt$'
    "copytext-objects.txt" = '^Copytext[^\\]*-sharedassets0\.assets-\d+\.txt$'
    "menu-language-files.txt" = '(?i)(Apply Language|ApplyLanguage|Continue|Settings|VideoSettingsPopup|MenuItemUI|Rebind|Reset|TranslationManager|Translate).*\.txt$'
    "failed-deserialize.txt" = '.*\.txt$'
}

foreach ($entry in $patterns.GetEnumerator()) {
    $name = $entry.Key
    $pattern = $entry.Value
    $target = Join-Path $resolvedOutputDir $name

    if ($name -eq "failed-deserialize.txt") {
        $files |
            Where-Object { $_.Extension -eq ".txt" } |
            Where-Object { Select-String -Path $_.FullName -Pattern 'Asset failed to deserialize\.' -Quiet } |
            Select-Object -ExpandProperty FullName |
            Set-Content -Encoding UTF8 $target
        continue
    }

    $files |
        Where-Object { $_.Name -match $pattern } |
        Select-Object -ExpandProperty FullName |
        Set-Content -Encoding UTF8 $target
}

$keywordHits = @(
    'tr-language-',
    'OnApplyLanguage',
    'TranslationManager',
    'Translate',
    'Continue',
    'Settings',
    'Rebind',
    'Reset',
    'Language'
)

$keywordReport = foreach ($keyword in $keywordHits) {
    [pscustomobject]@{
        Keyword = $keyword
        Matches = (rg -l -F $keyword $resolvedDumpDir 2>$null | Measure-Object).Count
    }
}

$keywordReport | Export-Csv -NoTypeInformation -Encoding UTF8 (Join-Path $resolvedOutputDir "keyword-hit-summary.csv")

Write-Host "Analysis written to $resolvedOutputDir"
