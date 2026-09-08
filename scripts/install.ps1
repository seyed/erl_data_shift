# Standalone installer for eds on Windows. Run in PowerShell:
#   irm https://raw.githubusercontent.com/seyed/erl_data_shift/main/scripts/install.ps1 | iex
$ErrorActionPreference = "Stop"

$Repo = "seyed/erl_data_shift"  
$InstallDir = "$env:LOCALAPPDATA\eds"

Write-Host "Fetching latest release info..."
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest"
$asset = $release.assets | Where-Object { $_.name -like "eds-windows*" } | Select-Object -First 1

if (-not $asset) {
    Write-Error "Could not find a Windows release asset. Check https://github.com/$Repo/releases manually."
    exit 1
}

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$zipPath = "$env:TEMP\eds-windows.zip"

Write-Host "Downloading $($asset.name)..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

Write-Host "Extracting to $InstallDir..."
Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
Remove-Item $zipPath

$binPath = "$InstallDir\bin"
Write-Host "Installed to $binPath"

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$binPath*") {
    Write-Host "Adding $binPath to your PATH..."
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$binPath", "User")
    Write-Host "Restart your terminal, then run: eds --help"
} else {
    Write-Host "Run: eds --help"
}