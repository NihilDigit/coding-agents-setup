# Thin bootstrap for remote installation.
#
# Review this file before running it with:
#   irm <raw-url>/install.ps1 | iex

param(
    [ValidateSet('Prompt', 'Codex', 'Claude', 'Both', 'None')]
    [string]$Agent = 'Prompt',
    [switch]$Yes,
    [switch]$NonInteractive,
    [switch]$SkipTools,
    [switch]$SkipProfile,
    [string]$Repo = 'NihilDigit/coding-agents-setup',
    [string]$Ref = 'main'
)

$ErrorActionPreference = 'Stop'

Write-Warning 'This bootstrap downloads and executes setup-windows.ps1 from GitHub. Review the repository before running it on a machine you care about.'

$archiveUrl = "https://github.com/$Repo/archive/refs/heads/$Ref.zip"
$tempRoot = Join-Path $env:TEMP ('coding-agents-setup-' + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tempRoot 'repo.zip'
$extractPath = Join-Path $tempRoot 'repo'

New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
Invoke-WebRequest -Uri $archiveUrl -OutFile $zipPath
Expand-Archive -LiteralPath $zipPath -DestinationPath $extractPath -Force

$setup = Get-ChildItem -LiteralPath $extractPath -Recurse -Filter 'setup-windows.ps1' | Select-Object -First 1
if (-not $setup) { throw 'setup-windows.ps1 was not found in the downloaded archive.' }

$args = @('-ExecutionPolicy', 'Bypass', '-File', $setup.FullName, '-Agent', $Agent)
if ($Yes) { $args += '-Yes' }
if ($NonInteractive) { $args += '-NonInteractive' }
if ($SkipTools) { $args += '-SkipTools' }
if ($SkipProfile) { $args += '-SkipProfile' }

& powershell @args
