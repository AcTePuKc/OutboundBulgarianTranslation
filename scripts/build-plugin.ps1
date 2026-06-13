param(
    [string]$Configuration = "Release",
    [string]$ProjectPath = "src\OutboundTranslationMod\OutboundTranslationMod.csproj",
    [string]$NuGetConfigPath = "NuGet.Config",
    [ValidateSet("csc", "dotnet")]
    [string]$Method = "csc",
    [string]$ResponseFile = "build\OutboundTranslationMod\compile.rsp",
    [string]$CscPath = "C:\Program Files\dotnet\sdk\10.0.300-preview.0.26177.108\Roslyn\bincore\csc.dll"
)

$ErrorActionPreference = "Stop"

if ($Method -eq "csc") {
    if (-not (Test-Path -LiteralPath $ResponseFile)) {
        throw "Response file not found: $ResponseFile"
    }

    if (-not (Test-Path -LiteralPath $CscPath)) {
        $sdk = dotnet --list-sdks |
            ForEach-Object {
                if ($_ -match '^(?<version>\S+)\s+\[(?<path>.+)\]$') {
                    [pscustomobject]@{
                        Version = $Matches.version
                        Path = $Matches.path
                        Csc = Join-Path $Matches.path "$($Matches.version)\Roslyn\bincore\csc.dll"
                    }
                }
            } |
            Where-Object { Test-Path -LiteralPath $_.Csc } |
            Sort-Object Version -Descending |
            Select-Object -First 1

        if ($sdk) {
            $CscPath = $sdk.Csc
        }
        else {
            throw "C# compiler not found: $CscPath"
        }
    }

    dotnet $CscPath "@$ResponseFile"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    return
}

if (-not (Test-Path -LiteralPath $ProjectPath)) {
    throw "Project not found: $ProjectPath"
}

$args = @("build", $ProjectPath, "-c", $Configuration)
if (Test-Path -LiteralPath $NuGetConfigPath) {
    $args += @("--configfile", $NuGetConfigPath)
}

dotnet @args
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
