param(
    [string]$CatalogPath = "C:\Program Files (x86)\Steam\steamapps\common\Outbound\Outbound_Data\StreamingAssets\aa\catalog.bin",
    [string]$OutputPath = "C:\WebStuff\Outbound-Mods\data\analysis\gnome-names-from-catalog.tsv"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $CatalogPath)) {
    throw "Catalog not found: $CatalogPath"
}

$bytes = [System.IO.File]::ReadAllBytes($CatalogPath)
$pattern = '(?<area>\d+) - gnome-(?<id>\d+) - (?<name>[^.\x00\r\n]+)\.png'
$texts = @(
    [System.Text.Encoding]::UTF8.GetString($bytes),
    [System.Text.Encoding]::Unicode.GetString($bytes)
)

$rows = foreach ($text in $texts) {
    foreach ($match in [regex]::Matches($text, $pattern)) {
        [pscustomobject]@{
            Area = [int]$match.Groups["area"].Value
            GnomeId = [int]$match.Groups["id"].Value
            Name = $match.Groups["name"].Value.Trim()
            Asset = $match.Value.Trim()
        }
    }
}

$rows = $rows |
    Sort-Object Area, GnomeId, Name -Unique |
    Sort-Object Area, GnomeId, Name

$outputDir = Split-Path -Parent $OutputPath
if ($outputDir) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

$lines = @("Area`tGnomeId`tName`tAsset")
$lines += $rows | ForEach-Object {
    "$($_.Area)`t$($_.GnomeId)`t$($_.Name)`t$($_.Asset)"
}

[System.IO.File]::WriteAllLines($OutputPath, $lines, [System.Text.UTF8Encoding]::new($false))

Write-Host "Extracted $($rows.Count) gnome names to $OutputPath"
