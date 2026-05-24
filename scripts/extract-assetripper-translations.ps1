param(
    [string]$InputPath = "data\assetripper-export-unity-project\ExportedProject\Assets\4 __Import txt\retrieved translations.txt",
    [string]$OutputPath = "data\translation\labels-from-assetripper.txt",
    [string]$TsvPath = "data\translation\assetripper-translations.tsv",
    [string]$MissingPath = "data\translation\missing-from-labels.txt",
    [string]$CurrentTranslationPath = "src\OutboundTranslationMod\translations\labels.txt"
)

$ErrorActionPreference = "Stop"

function Read-LabelKeys {
    param([string]$Path)

    $keys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $keys
    }

    foreach ($line in [System.IO.File]::ReadLines((Resolve-Path -LiteralPath $Path))) {
        $trimmed = $line.Trim()
        if ($trimmed.Length -eq 0 -or $trimmed.StartsWith("#")) {
            continue
        }

        $equals = $trimmed.IndexOf("=")
        if ($equals -le 0) {
            continue
        }

        [void]$keys.Add($trimmed.Substring(0, $equals))
    }

    return $keys
}

$resolvedInput = Resolve-Path -LiteralPath $InputPath
$json = Get-Content -LiteralPath $resolvedInput -Raw -Encoding UTF8
$rows = $json | ConvertFrom-Json -AsHashtable

$outDir = Split-Path -Parent $OutputPath
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$items = foreach ($row in $rows) {
    $id = [string]$row["ID"]
    $en = [string]$row["En"]
    $description = [string]$row["Optional description"]
    if ([string]::IsNullOrWhiteSpace($id) -or [string]::IsNullOrWhiteSpace($en)) {
        continue
    }

    [pscustomobject]@{
        ID = $id.Trim()
        En = $en.Replace("`r`n", "\n").Replace("`n", "\n").Trim()
        Description = $description.Replace("`r`n", "\n").Replace("`n", "\n").Trim()
    }
}

$deduped = $items |
    Group-Object -Property ID |
    ForEach-Object { $_.Group | Select-Object -First 1 } |
    Sort-Object -Property ID

$labelLines = foreach ($item in $deduped) {
    "{0}={1}" -f $item.ID, $item.En
}

[System.IO.File]::WriteAllLines((Join-Path (Get-Location) $OutputPath), $labelLines, [System.Text.UTF8Encoding]::new($false))

$tsvLines = @("ID`tEn`tDescription")
$tsvLines += foreach ($item in $deduped) {
    "{0}`t{1}`t{2}" -f $item.ID, $item.En.Replace("`t", " "), $item.Description.Replace("`t", " ")
}

[System.IO.File]::WriteAllLines((Join-Path (Get-Location) $TsvPath), $tsvLines, [System.Text.UTF8Encoding]::new($false))

$currentKeys = Read-LabelKeys -Path $CurrentTranslationPath
$missing = @(foreach ($item in $deduped) {
    if (-not $currentKeys.Contains($item.ID)) {
        "{0}={1}" -f $item.ID, $item.En
    }
})

[System.IO.File]::WriteAllLines((Join-Path (Get-Location) $MissingPath), $missing, [System.Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    SourceRows = @($rows).Count
    Extracted = @($deduped).Count
    CurrentKeys = $currentKeys.Count
    Missing = @($missing).Count
    OutputPath = (Resolve-Path -LiteralPath $OutputPath).Path
    TsvPath = (Resolve-Path -LiteralPath $TsvPath).Path
    MissingPath = (Resolve-Path -LiteralPath $MissingPath).Path
}
