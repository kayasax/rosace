<#
.SYNOPSIS
    Rosace installer — run with:
    irm https://raw.githubusercontent.com/kayasax/rosace/main/install.ps1 | iex
#>

$repo    = "kayasax/rosace"
$installDir = "~\.copilot\m-skills\rosace"
$skillDir   = Join-Path $HOME ".copilot\m-skills\rosace"

Write-Host ""
Write-Host "  Installing Rosace..." -ForegroundColor Magenta

# 1. Get latest release zip URL
$release  = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"
$zipUrl   = ($release.assets | Where-Object { $_.name -like "*.zip" }).browser_download_url
$version  = $release.tag_name

# 2. Download and extract
$tmpZip = Join-Path $env:TEMP "rosace.zip"
Invoke-WebRequest $zipUrl -OutFile $tmpZip
if (Test-Path $installDir) { Remove-Item $installDir -Recurse -Force }
Expand-Archive $tmpZip $installDir -Force
Remove-Item $tmpZip

# 3. Install Scout skill
New-Item -ItemType Directory -Force $skillDir | Out-Null
Copy-Item "$installDir\skill\SKILL.md" "$skillDir\SKILL.md" -Force

# 4. Config (first install only)
$configDst = "$installDir\config\config.json"
if (-not (Test-Path $configDst)) {
    Copy-Item "$installDir\config\config.example.json" $configDst
}

Write-Host ""
Write-Host "  Rosace $version installed." -ForegroundColor Green
Write-Host "  Skill: $skillDir\SKILL.md" -ForegroundColor Gray
Write-Host "  Files: $installDir" -ForegroundColor Gray
Write-Host ""
Write-Host "  In Microsoft Scout, type: set up rosace" -ForegroundColor Cyan
Write-Host ""

