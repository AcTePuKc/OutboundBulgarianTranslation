param(
    [string]$Version = "0.1.4",
    [string]$OutputDir = "dist",
    [string]$BuildDllPath = "build\OutboundTranslationMod\OutboundTranslationMod.dll",
    [string]$LabelsPath = "src\OutboundTranslationMod\translations\labels.txt",
    [string]$GnomeNamesPath = "src\OutboundTranslationMod\translations\gnome-names.txt"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $BuildDllPath)) {
    throw "Build DLL not found: $BuildDllPath. Run scripts\build-plugin.ps1 first."
}

if (-not (Test-Path -LiteralPath $LabelsPath)) {
    throw "Translation file not found: $LabelsPath"
}

$root = Join-Path $OutputDir "OutboundTranslationMod-$Version"
$pluginDir = Join-Path $root "BepInEx\plugins\OutboundTranslationMod"
$translationsDir = Join-Path $pluginDir "translations"
$configDir = Join-Path $root "BepInEx\config"

if (Test-Path -LiteralPath $root) {
    Remove-Item -LiteralPath $root -Recurse -Force
}

New-Item -ItemType Directory -Path $translationsDir -Force | Out-Null
New-Item -ItemType Directory -Path $configDir -Force | Out-Null

Copy-Item -LiteralPath $BuildDllPath -Destination (Join-Path $pluginDir "OutboundTranslationMod.dll") -Force
Copy-Item -LiteralPath $LabelsPath -Destination (Join-Path $translationsDir "labels.txt") -Force
if (Test-Path -LiteralPath $GnomeNamesPath) {
    Copy-Item -LiteralPath $GnomeNamesPath -Destination (Join-Path $translationsDir "gnome-names.txt") -Force
}
Copy-Item -LiteralPath "release\OutboundTranslationMod.cfg" -Destination (Join-Path $configDir "actepukc.outbound.uitranslationbulgarian.cfg") -Force
Copy-Item -LiteralPath "release\README-Nexus.txt" -Destination (Join-Path $root "README.txt") -Force
Copy-Item -LiteralPath "LICENSE" -Destination (Join-Path $root "LICENSE.txt") -Force
Copy-Item -LiteralPath "NOTICE.md" -Destination (Join-Path $root "NOTICE.md") -Force

$zipPath = Join-Path $OutputDir "OutboundTranslationMod-$Version.zip"
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path (Join-Path $root "*") -DestinationPath $zipPath -Force

[pscustomobject]@{
    PackageRoot = (Resolve-Path -LiteralPath $root).Path
    ZipPath = (Resolve-Path -LiteralPath $zipPath).Path
}
