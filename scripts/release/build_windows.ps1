# Builds a Windows release package for eds.
# Must run on Windows (relx bundles a platform-specific ERTS — no cross-compiling).
$ErrorActionPreference = "Stop"

Write-Host "Building Windows release..."
rebar3 as prod release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$relDir = "_build/prod/rel/erl_data_shift"
$binDir = "$relDir/bin"

# Windows has no equivalent to the bash self-extracting wrapper trick, so we
# ship a .zip instead. This thin eds.cmd wrapper mirrors what the bash
# wrappers do on macOS/Linux: inject "foreground" so users type
# `eds <command>` instead of `eds foreground <command>`, and set
# EDS_ORIGINAL_CWD so .env lookup works from wherever the user runs it,
# regardless of whether relx's own launcher changes the working directory.
$wrapperContent = @"
@echo off
set EDS_ORIGINAL_CWD=%CD%
"%~dp0erl_data_shift.cmd" foreground %*
"@
Set-Content -Path "$binDir/eds.cmd" -Value $wrapperContent -Encoding ASCII

$outDir = "_build/prod/bin"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$zipPath = "$outDir/eds-windows-x86_64.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath }

Compress-Archive -Path "$relDir/*" -DestinationPath $zipPath

Write-Host "Windows package ready at: $zipPath"
Write-Host "Entry point after extracting: bin\eds.cmd"