param(
    [string]$GameDir = "C:\Program Files (x86)\Steam\steamapps\common\Outbound",
    [string]$OutputDir = ".\data\raw"
)

$ErrorActionPreference = "Stop"

function Get-AsciiStrings {
    param(
        [byte[]]$Bytes,
        [int]$MinLength = 4
    )

    $buffer = New-Object System.Collections.Generic.List[byte]

    for ($i = 0; $i -lt $Bytes.Length; $i++) {
        $b = $Bytes[$i]
        if ($b -ge 32 -and $b -le 126) {
            [void]$buffer.Add($b)
        } else {
            if ($buffer.Count -ge $MinLength) {
                [System.Text.Encoding]::ASCII.GetString($buffer.ToArray())
            }
            $buffer.Clear()
        }
    }

    if ($buffer.Count -ge $MinLength) {
        [System.Text.Encoding]::ASCII.GetString($buffer.ToArray())
    }
}

function Get-Utf16LeStrings {
    param(
        [byte[]]$Bytes,
        [int]$MinLength = 4
    )

    $chars = New-Object System.Collections.Generic.List[char]
    $i = 0

    while ($i -lt ($Bytes.Length - 1)) {
        $lo = $Bytes[$i]
        $hi = $Bytes[$i + 1]

        if ($hi -eq 0 -and $lo -ge 32 -and $lo -le 126) {
            [void]$chars.Add([char]$lo)
            $i += 2
            continue
        }

        if ($chars.Count -ge $MinLength) {
            -join $chars
        }
        $chars.Clear()
        $i += 1
    }

    if ($chars.Count -ge $MinLength) {
        -join $chars
    }
}

function Test-UiCandidate {
    param([string]$Value)

    if ($Value.Length -lt 4) { return $false }
    if ($Value.Length -gt 120) { return $false }
    if ($Value -match '^[0-9 .,:;_\-]+$') { return $false }
    if ($Value -match '^[A-Za-z0-9_.]+\.(png|jpg|jpeg|mat|shader|prefab|asset|json|dll)$') { return $false }

    $keywords = @(
        "Continue", "Settings", "Reset", "Rebind", "Apply", "Back", "Exit",
        "Language", "Video", "Audio", "Gameplay", "Controls", "Map",
        "Craft", "Inventory", "Repair", "Camp", "Drive", "Sleep",
        "Hotkey", "Description", "Unit", "Value", "Selected",
        "Copytext", "Label", "Paragraph", "Placeholder", "Current",
        "Transfer", "Container", "Slot", "OnApplyLanguage", "tr-language-"
    )

    foreach ($keyword in $keywords) {
        if ($Value -like "*$keyword*") {
            return $true
        }
    }

    if ($Value -cmatch '^[A-Z][A-Za-z0-9 /_-]{3,60}$') {
        return $true
    }

    return $false
}

$resolvedGameDir = (Resolve-Path $GameDir).Path
$resolvedOutputDir = [System.IO.Path]::GetFullPath($OutputDir)
[System.IO.Directory]::CreateDirectory($resolvedOutputDir) | Out-Null

$targets = @(
    "Outbound_Data\sharedassets0.assets",
    "Outbound_Data\resources.assets",
    "Outbound_Data\globalgamemanagers.assets",
    "Outbound_Data\il2cpp_data\Metadata\global-metadata.dat"
)

$allStrings = New-Object System.Collections.Generic.HashSet[string] ([System.StringComparer]::Ordinal)

foreach ($relativePath in $targets) {
    $fullPath = Join-Path $resolvedGameDir $relativePath
    if (-not (Test-Path $fullPath)) {
        Write-Warning "Missing target: $fullPath"
        continue
    }

    Write-Host "Scanning $fullPath"
    $bytes = [System.IO.File]::ReadAllBytes($fullPath)

    foreach ($value in Get-AsciiStrings -Bytes $bytes) {
        [void]$allStrings.Add($value)
    }
    foreach ($value in Get-Utf16LeStrings -Bytes $bytes) {
        [void]$allStrings.Add($value)
    }
}

$allSorted = $allStrings | Sort-Object
$allPath = Join-Path $resolvedOutputDir "all-strings.txt"
$uiPath = Join-Path $resolvedOutputDir "filtered-ui-candidates.txt"
$langPath = Join-Path $resolvedOutputDir "language-candidates.txt"

$allSorted | Set-Content -Encoding UTF8 $allPath
$allSorted | Where-Object { Test-UiCandidate $_ } | Set-Content -Encoding UTF8 $uiPath
$allSorted | Where-Object { $_ -like "*tr-language-*" -or $_ -like "*Language*" -or $_ -like "*OnApplyLanguage*" } | Set-Content -Encoding UTF8 $langPath

Write-Host "Wrote:"
Write-Host "  $allPath"
Write-Host "  $uiPath"
Write-Host "  $langPath"
