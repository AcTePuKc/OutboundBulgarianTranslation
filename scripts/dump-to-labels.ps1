param(
    [string]$DumpPath = "C:\Program Files (x86)\Steam\steamapps\common\Outbound\BepInEx\plugins\OutboundTranslationMod\dumps\translation-dump.txt",
    [string]$OutputPath = ".\data\translation\labels-bg.generated.txt"
)

$ErrorActionPreference = "Stop"

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputPath)
$outputDir = [System.IO.Path]::GetDirectoryName($resolvedOutput)
[System.IO.Directory]::CreateDirectory($outputDir) | Out-Null

$entries = [ordered]@{}

foreach ($line in [System.IO.File]::ReadLines($DumpPath, [System.Text.Encoding]::UTF8)) {
    if ([string]::IsNullOrWhiteSpace($line)) {
        continue
    }

    $parts = $line -split "`t", 3
    if ($parts.Count -lt 3) {
        continue
    }

    $key = $parts[1].Trim()
    $value = $parts[2]

    if ($key.Length -eq 0 -or $entries.Contains($key)) {
        continue
    }

    $entries[$key] = $value
}

$content = New-Object System.Collections.Generic.List[string]
[void]$content.Add("# Generated from Outbound runtime translation dump.")
[void]$content.Add("# Translate the values after '=' and keep the tr-* keys unchanged.")
[void]$content.Add("")

foreach ($key in ($entries.Keys | Sort-Object)) {
    [void]$content.Add("$key=$($entries[$key])")
}

[System.IO.File]::WriteAllLines($resolvedOutput, $content, [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote $($entries.Count) labels to $resolvedOutput"
