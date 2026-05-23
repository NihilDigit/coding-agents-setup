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
    [string]$Ref = '',
    [ValidateSet('sha', 'tag', 'branch')]
    [string]$RefKind = 'sha'
)

$ErrorActionPreference = 'Stop'

Write-Warning 'This bootstrap downloads and executes setup-windows.ps1 from GitHub. Review the repository before running it on a machine you care about.'

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-PwshCommand {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) { return $pwsh }

    $candidateRoots = @(
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        $(if ($env:LOCALAPPDATA) { Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links' })
    ) | Where-Object { $_ }
    $candidates = foreach ($root in $candidateRoots) {
        if ((Split-Path -Leaf $root) -eq 'Links') {
            Join-Path $root 'pwsh.exe'
        } else {
            Join-Path $root 'PowerShell\7\pwsh.exe'
        }
    }
    $candidates = @($candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })

    if ($candidates) {
        $pwshPath = $candidates[0]
        $pwshDir = Split-Path -Parent $pwshPath
        if (($env:Path -split ';') -notcontains $pwshDir) {
            $env:Path += ";$pwshDir"
        }
        return Get-Command $pwshPath -ErrorAction SilentlyContinue
    }

    return $null
}

try {
    if ((Get-ExecutionPolicy -Scope CurrentUser) -ne 'RemoteSigned') {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    }
} catch {
    Write-Warning "Could not set CurrentUser execution policy to RemoteSigned: $($_.Exception.Message)"
}

if (-not (Get-PwshCommand)) {
    if (-not (Test-Command winget)) {
        throw 'PowerShell 7 (pwsh) is not installed, and winget is unavailable. Install PowerShell 7 from Microsoft.PowerShell or install App Installer, then rerun this bootstrap.'
    }

    Write-Host 'Installing PowerShell 7 (Microsoft.PowerShell) with winget'
    winget install --id Microsoft.PowerShell -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget failed to install PowerShell 7 with exit code $LASTEXITCODE."
    }
}

if ([string]::IsNullOrWhiteSpace($Ref)) {
    $runs = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/actions/workflows/smoke.yml/runs?status=success&event=push&per_page=50"
    $run = @($runs.workflow_runs | Where-Object { $_.head_branch -like 'ci-*' -and $_.head_sha } | Select-Object -First 1)
    if (-not $run) {
        throw "Could not determine latest successful ci-* tag for $Repo. Set -Ref and -RefKind explicitly."
    }
    $ciTag = $run[0].head_branch
    $Ref = $run[0].head_sha
    $RefKind = 'sha'
}

if ($RefKind -eq 'sha') {
    if ($ciTag) {
        Write-Host "Using latest successful CI tag $ciTag at $Ref from $Repo"
    } else {
        Write-Host "Using commit $Ref from $Repo"
    }
    $archiveUrl = "https://github.com/$Repo/archive/$Ref.zip"
} else {
    Write-Host "Using $RefKind $Ref from $Repo"
    $refPath = if ($RefKind -eq 'tag') { 'tags' } else { 'heads' }
    $archiveUrl = "https://github.com/$Repo/archive/refs/$refPath/$Ref.zip"
}
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

$pwsh = Get-PwshCommand
if (-not $pwsh) {
    throw 'PowerShell 7 (pwsh) is still unavailable after installation.'
}

& $pwsh.Source @args
