param(
    [string]$AppRepoPath = "..\Gainz"
)

$ErrorActionPreference = "Stop"

$resolvedApp = (Resolve-Path -LiteralPath $AppRepoPath).Path
$screenshotSource = Join-Path $resolvedApp "docs\assets\screenshots"
$screenshotDestination = Join-Path $PSScriptRoot "..\assets\screenshots"

if (-not (Test-Path -LiteralPath $screenshotSource)) {
    throw "Screenshot source not found: $screenshotSource"
}

if (-not (Test-Path -LiteralPath $screenshotDestination)) {
    New-Item -ItemType Directory -Path $screenshotDestination | Out-Null
}

Copy-Item -Path (Join-Path $screenshotSource "*.png") -Destination $screenshotDestination -Force

Write-Host "Copied screenshots from $screenshotSource"
