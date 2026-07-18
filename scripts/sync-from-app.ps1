param(
    [string]$AppRepoPath = "..\Gainz"
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$resolvedApp = (Resolve-Path -LiteralPath $AppRepoPath).Path
$versionPath = Join-Path $resolvedApp "VERSION"
$screenshotSource = Join-Path $resolvedApp "docs\assets\screenshots"
$screenshotDestination = Join-Path $repoRoot "assets\screenshots"
$downloadSource = Join-Path $resolvedApp "docs\assets\downloads"
$downloadDestination = Join-Path $repoRoot "assets\downloads"
$sampleMetadataSource = Join-Path $downloadSource "gainz-synthetic-audit-packet-sample.json"

if (-not (Test-Path -LiteralPath $versionPath)) {
    throw "VERSION file not found: $versionPath"
}

$version = (Get-Content -LiteralPath $versionPath -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$') {
    throw "Unexpected Gainz VERSION value: $version"
}

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

function Update-WebsiteFile {
    param(
        [string]$RelativePath,
        [scriptblock]$Updater
    )

    $path = Join-Path $repoRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Website file not found: $path"
    }

    $original = Get-Content -LiteralPath $path -Raw
    $updated = & $Updater $original
    if ($updated -ne $original) {
        Write-Utf8NoBom -Path $path -Content $updated
        Write-Host "Updated $RelativePath"
    }
}

function Update-VersionText {
    param([string]$Text)

    $semver = '\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?'
    $updated = $Text
    $updated = [regex]::Replace($updated, '("softwareVersion":\s*")[^"]+(")', {
        param($match)
        $match.Groups[1].Value + $version + $match.Groups[2].Value
    })
    $updated = [regex]::Replace($updated, "(Latest release\s+)$semver", {
        param($match)
        $match.Groups[1].Value + $version
    })
    $updated = [regex]::Replace($updated, "(Version\s+)$semver", {
        param($match)
        $match.Groups[1].Value + $version
    })
    $updated = [regex]::Replace($updated, "(Gainz\s+)$semver", {
        param($match)
        $match.Groups[1].Value + $version
    })

    return $updated
}

if (-not (Test-Path -LiteralPath $screenshotSource)) {
    throw "Screenshot source not found: $screenshotSource"
}

if (-not (Test-Path -LiteralPath $screenshotDestination)) {
    New-Item -ItemType Directory -Path $screenshotDestination | Out-Null
}

$screenshots = Get-ChildItem -LiteralPath $screenshotSource -Filter "*.png" -File
if ($screenshots.Count -eq 0) {
    Write-Warning "No screenshots found in $screenshotSource"
} else {
    foreach ($screenshot in $screenshots) {
        Copy-Item -LiteralPath $screenshot.FullName -Destination $screenshotDestination -Force
    }
    Write-Host "Copied screenshots from $screenshotSource"
}

if (Test-Path -LiteralPath $downloadSource) {
    if (-not (Test-Path -LiteralPath $downloadDestination)) {
        New-Item -ItemType Directory -Path $downloadDestination | Out-Null
    }

    $downloads = Get-ChildItem -LiteralPath $downloadSource -File
    foreach ($download in $downloads) {
        Copy-Item -LiteralPath $download.FullName -Destination $downloadDestination -Force
    }
    Write-Host "Copied sample downloads from $downloadSource"
}

$htmlFiles = @(
    "index.html",
    "download\index.html",
    "sample-packet\index.html"
)

foreach ($htmlFile in $htmlFiles) {
    Update-WebsiteFile -RelativePath $htmlFile -Updater {
        param($text)
        Update-VersionText -Text $text
    }
}

$sampleZipPath = Join-Path $downloadDestination "gainz-synthetic-audit-packet-sample.zip"
if (Test-Path -LiteralPath $sampleZipPath) {
    $sampleHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sampleZipPath).Hash.ToLowerInvariant()
    $sampleGeneratedDate = $null
    if (Test-Path -LiteralPath $sampleMetadataSource) {
        $sampleMetadata = Get-Content -LiteralPath $sampleMetadataSource -Raw | ConvertFrom-Json
        if ($sampleMetadata.sha256 -and $sampleMetadata.sha256.ToLowerInvariant() -ne $sampleHash) {
            throw "Synthetic sample metadata checksum does not match the ZIP."
        }
        if ($sampleMetadata.version -and $sampleMetadata.version -ne $version) {
            throw "Synthetic sample metadata version $($sampleMetadata.version) does not match Gainz $version."
        }
        if ($sampleMetadata.generated_date) {
            $sampleGeneratedDate = [datetime]::ParseExact(
                $sampleMetadata.generated_date,
                "yyyy-MM-dd",
                [System.Globalization.CultureInfo]::InvariantCulture
            ).ToString("MMMM d, yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
        }
    }
    Update-WebsiteFile -RelativePath "sample-packet\index.html" -Updater {
        param($text)
        $updated = [regex]::Replace($text, '(<span>SHA-256</span>\s*<code>)[0-9a-fA-F]{64}(</code>)', {
            param($match)
            $match.Groups[1].Value + $sampleHash + $match.Groups[2].Value
        })
        if ($sampleGeneratedDate) {
            $updated = [regex]::Replace($updated, 'Generated\s+[A-Z][a-z]+\s+\d{1,2},\s+\d{4}', "Generated $sampleGeneratedDate")
        }
        $updated
    }
}

Write-Host "Website sync complete for Gainz $version"
