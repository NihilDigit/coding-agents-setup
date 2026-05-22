# Coding Agents Windows Setup
# Interactive Windows bootstrap for shared coding-agent rules and shell ergonomics.
#
# Usage:
#   .\setup-windows.ps1
#   .\setup-windows.ps1 -Agent Both -Yes
#   .\setup-windows.ps1 -Agent Codex -NonInteractive

param(
    [ValidateSet('Prompt', 'Codex', 'Claude', 'Both', 'None')]
    [string]$Agent = 'Prompt',
    [switch]$Yes,
    [switch]$NonInteractive,
    [switch]$SkipTools,
    [switch]$SkipProfile
)

$ErrorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Confirm-Step {
    param(
        [Parameter(Mandatory = $true)][string]$Prompt,
        [bool]$Default = $true
    )

    if ($Yes) { return $true }
    if ($NonInteractive) { return $Default }

    $suffix = if ($Default) { '[Y/n]' } else { '[y/N]' }
    $answer = Read-Host "$Prompt $suffix"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer.Trim().ToLowerInvariant().StartsWith('y')
}

function Select-AgentTarget {
    if ($Agent -ne 'Prompt') { return $Agent }
    if ($NonInteractive) { return 'Both' }

    Write-Host 'Which coding agent should be configured?'
    Write-Host '  1. Codex'
    Write-Host '  2. Claude Code'
    Write-Host '  3. Both'
    Write-Host '  4. Shared tooling only'
    $answer = Read-Host 'Select [1-4] (default: 3)'
    switch ($answer.Trim()) {
        '1' { return 'Codex' }
        '2' { return 'Claude' }
        '4' { return 'None' }
        default { return 'Both' }
    }
}

function Add-SessionPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ((Test-Path -LiteralPath $Path) -and (($env:Path -split ';') -notcontains $Path)) {
        $env:Path += ";$Path"
    }
}

function Set-TextFileLf {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Text
    )
    $normalized = ($Text -replace "`r`n", "`n").TrimEnd() + "`n"
    [System.IO.File]::WriteAllText($Path, $normalized, [System.Text.UTF8Encoding]::new($false))
}

function Backup-Path {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $null }

    $backupRoot = Join-Path $HOME ('.coding-agents-backup-' + (Get-Date -Format 'yyyyMMddHHmmss'))
    New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null
    $dest = Join-Path $backupRoot ((Split-Path -Leaf (Split-Path -Parent $Path)) + '-' + (Split-Path -Leaf $Path))
    if (Test-Path -LiteralPath $dest) {
        $dest = $dest + '-' + ([guid]::NewGuid().ToString('N').Substring(0, 8))
    }
    Copy-Item -LiteralPath $Path -Destination $dest -Recurse -Force
    return $dest
}

function Get-RuleText {
    param([Parameter(Mandatory = $true)][string[]]$Names)
    $parts = foreach ($name in $Names) {
        $path = Join-Path $ScriptRoot (Join-Path 'rules' $name)
        if (-not (Test-Path -LiteralPath $path)) { throw "Missing rule file: $path" }
        (Get-Content -LiteralPath $path -Raw).Trim()
    }
    return ($parts -join "`n`n")
}

function Write-AgentRules {
    param([Parameter(Mandatory = $true)][string]$Target)

    $sharedFiles = @('AGENTS.shared.md')
    if ($IsWindows -or $env:OS -eq 'Windows_NT') {
        $sharedFiles += 'AGENTS.windows.md'
    }

    if ($Target -eq 'Codex' -or $Target -eq 'Both') {
        $codexDir = Join-Path $HOME '.codex'
        $codexPath = Join-Path $codexDir 'AGENTS.md'
        New-Item -ItemType Directory -Force -Path $codexDir | Out-Null
        $backup = Backup-Path $codexPath
        if ($backup) { Write-Host "Backed up $codexPath -> $backup" }
        $text = Get-RuleText ($sharedFiles + 'AGENTS.codex.md')
        Set-TextFileLf -Path $codexPath -Text $text
        Write-Host "Wrote $codexPath"
    }

    if ($Target -eq 'Claude' -or $Target -eq 'Both') {
        $claudeDir = Join-Path $HOME '.claude'
        $claudePath = Join-Path $claudeDir 'CLAUDE.md'
        New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
        $backup = Backup-Path $claudePath
        if ($backup) { Write-Host "Backed up $claudePath -> $backup" }
        $text = Get-RuleText ($sharedFiles + 'CLAUDE.md')
        Set-TextFileLf -Path $claudePath -Text $text
        Write-Host "Wrote $claudePath"
    }
}

function Install-WinGetPackage {
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$Command,
        [string]$DisplayName = $Command
    )

    if (Test-Command $Command) {
        Write-Host "Already available: $Command"
        return
    }
    if (-not (Test-Command winget)) {
        throw "winget is required to install $DisplayName ($Id). Install App Installer from Microsoft Store, then rerun this script."
    }

    Write-Host "Installing $DisplayName ($Id)"
    winget install --id $Id -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget failed to install $DisplayName ($Id) with exit code $LASTEXITCODE."
    }
}

function Install-BunGlobal {
    param(
        [Parameter(Mandatory = $true)][string]$Package,
        [Parameter(Mandatory = $true)][string]$Command,
        [string]$DisplayName = $Package
    )

    if (Test-Command $Command) {
        Write-Host "Already available: $Command"
        return
    }
    if (-not (Test-Command bun)) {
        Write-Warning "bun is not available; skipping $DisplayName"
        return
    }

    Write-Host "Installing $DisplayName with bun"
    bun install -g $Package
    Add-SessionPath (Join-Path $HOME '.bun\bin')
}

function Test-DeveloperMode {
    try {
        $value = Get-ItemPropertyValue -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction Stop
        return ($value -eq 1)
    } catch {
        return $false
    }
}

function Configure-SkillsLayout {
    $agentsSkills = Join-Path $HOME '.agents\skills'
    $claudeSkills = Join-Path $HOME '.claude\skills'
    $codexSkills = Join-Path $HOME '.codex\skills'

    New-Item -ItemType Directory -Force -Path $agentsSkills | Out-Null

    if (Test-Path -LiteralPath $claudeSkills) {
        $item = Get-Item -LiteralPath $claudeSkills -Force
        if ($item.LinkType -eq 'SymbolicLink' -or $item.LinkType -eq 'Junction') {
            Remove-Item -LiteralPath $claudeSkills -Force
        } else {
            $backup = Backup-Path $claudeSkills
            if ($backup) { Write-Host "Backed up $claudeSkills -> $backup" }
            Move-Item -LiteralPath $claudeSkills -Destination ($claudeSkills + '.old-' + (Get-Date -Format 'yyyyMMddHHmmss')) -Force
        }
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $claudeSkills) | Out-Null
    try {
        New-Item -ItemType SymbolicLink -Path $claudeSkills -Target $agentsSkills | Out-Null
    } catch {
        $devModeHint = if (Test-DeveloperMode) { 'Developer Mode appears enabled.' } else { 'Developer Mode does not appear enabled.' }
        Write-Warning "Could not create symlink $claudeSkills -> $agentsSkills. $devModeHint Falling back to a directory junction."
        New-Item -ItemType Junction -Path $claudeSkills -Target $agentsSkills | Out-Null
    }

    New-Item -ItemType Directory -Force -Path $codexSkills | Out-Null
}

function Install-DefaultSkills {
    if (-not (Test-Command bun)) {
        Write-Warning 'bun is not available; skipping Agent Skills install.'
        return
    }

    Write-Warning 'This downloads and installs Agent Skills from GitHub repositories. Review the repository URLs before continuing on untrusted networks.'
    bunx skills add https://github.com/NihilDigit/writing-style -g -s writing-style -y
    bunx skills add https://github.com/pbakaus/impeccable -g -s impeccable -y
}

function Install-KimiWebBridge {
    if (-not (Test-Command irm)) {
        Write-Warning 'Invoke-RestMethod alias irm is not available; skipping Kimi WebBridge.'
        return
    }
    if ((Test-Command kimi-webbridge) -or (Test-Command webbridge)) {
        Write-Host 'Kimi WebBridge appears to be installed.'
        return
    }

    Write-Warning 'This downloads and executes the current PowerShell installer returned by https://cdn.kimi.com/webbridge/install.ps1.'
    irm https://cdn.kimi.com/webbridge/install.ps1 | iex
    Add-SessionPath (Join-Path $HOME '.kimi-webbridge\bin')
}

function Write-PowerShellProfiles {
    $profileBlockPath = Join-Path $ScriptRoot 'profiles\Microsoft.PowerShell_profile.block.ps1'
    if (-not (Test-Path -LiteralPath $profileBlockPath)) { throw "Missing profile block: $profileBlockPath" }
    $profileBlock = (Get-Content -LiteralPath $profileBlockPath -Raw).TrimEnd()

    $profiles = @(
        (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
        (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1')
    )

    foreach ($profilePath in $profiles) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $profilePath) | Out-Null
        $content = if (Test-Path -LiteralPath $profilePath) { Get-Content -LiteralPath $profilePath -Raw } else { '' }
        $content = [regex]::Replace($content, '(?s)\r?\n?# BEGIN (Codex CLI|Coding Agents) ergonomics.*?# END (Codex CLI|Coding Agents) ergonomics\r?\n?', "`n")
        $content = $content.TrimEnd()
        $newContent = if ($content) { $content + "`n`n" + $profileBlock + "`n" } else { $profileBlock + "`n" }
        Set-TextFileLf -Path $profilePath -Text $newContent
        Write-Host "Wrote $profilePath"
    }
}

Write-Host 'Coding Agents Windows Setup'
$targetAgent = Select-AgentTarget

if ($targetAgent -ne 'None') {
    Write-AgentRules -Target $targetAgent
}

if (-not $SkipTools) {
    if (Confirm-Step 'Ensure Git is installed?' $true) {
        Install-WinGetPackage -Id 'Git.Git' -Command 'git' -DisplayName 'Git'
    }

    if (Confirm-Step 'Install GitHub CLI (gh)? Useful for authenticated GitHub workflows.' $false) {
        Install-WinGetPackage -Id 'GitHub.cli' -Command 'gh' -DisplayName 'GitHub CLI'
    }

    if (Confirm-Step 'Ensure uv is installed?' $true) {
        Install-WinGetPackage -Id 'astral-sh.uv' -Command 'uv' -DisplayName 'uv'
    }

    if (Confirm-Step 'Ensure Bun is installed?' $true) {
        Install-WinGetPackage -Id 'Oven-sh.Bun' -Command 'bun' -DisplayName 'Bun'
    }

    Add-SessionPath (Join-Path $HOME 'AppData\Local\Microsoft\WinGet\Links')
    Add-SessionPath (Join-Path $HOME '.bun\bin')
    Add-SessionPath (Join-Path $HOME 'scoop\shims')
    Add-SessionPath 'C:\Program Files\bottom\bin'

    if (Confirm-Step 'Install Codex CLI with bun if missing?' ($targetAgent -eq 'Codex' -or $targetAgent -eq 'Both')) {
        Install-BunGlobal -Package '@openai/codex' -Command 'codex' -DisplayName 'Codex CLI'
    }

    if (Confirm-Step 'Install cross-platform trash CLI with bun if missing?' $true) {
        Install-BunGlobal -Package 'trash-cli' -Command 'trash' -DisplayName 'trash-cli'
    }

    if (Confirm-Step 'Install modern CLI tools (eza, zoxide, bat, rg, fd, fzf, jq, dust, duf, procs, bottom, delta)?' $true) {
        $modernPackages = @(
            @{ Id = 'eza-community.eza'; Command = 'eza'; DisplayName = 'eza' },
            @{ Id = 'ajeetdsouza.zoxide'; Command = 'zoxide'; DisplayName = 'zoxide' },
            @{ Id = 'sharkdp.bat'; Command = 'bat'; DisplayName = 'bat' },
            @{ Id = 'BurntSushi.ripgrep.MSVC'; Command = 'rg'; DisplayName = 'ripgrep' },
            @{ Id = 'sharkdp.fd'; Command = 'fd'; DisplayName = 'fd' },
            @{ Id = 'junegunn.fzf'; Command = 'fzf'; DisplayName = 'fzf' },
            @{ Id = 'jqlang.jq'; Command = 'jq'; DisplayName = 'jq' },
            @{ Id = 'bootandy.dust'; Command = 'dust'; DisplayName = 'dust' },
            @{ Id = 'muesli.duf'; Command = 'duf'; DisplayName = 'duf' },
            @{ Id = 'dalance.procs'; Command = 'procs'; DisplayName = 'procs' },
            @{ Id = 'Clement.bottom'; Command = 'btm'; DisplayName = 'bottom' },
            @{ Id = 'dandavison.delta'; Command = 'delta'; DisplayName = 'delta' }
        )
        foreach ($pkg in $modernPackages) {
            Install-WinGetPackage -Id $pkg.Id -Command $pkg.Command -DisplayName $pkg.DisplayName
        }
    }

    if (Confirm-Step 'Normalize Agent Skills layout (.agents as user skill store, .claude skills link, .codex skills directory)?' ($targetAgent -eq 'Claude' -or $targetAgent -eq 'Both')) {
        Configure-SkillsLayout
    }

    if (Confirm-Step 'Install default Agent Skills (writing-style, impeccable)?' $true) {
        Install-DefaultSkills
    }

    if (Confirm-Step 'Install Kimi WebBridge? Downloads and executes the current installer from kimi.com; browser extension required for full automation.' $false) {
        Install-KimiWebBridge
    }
}

if (-not $SkipProfile -and (Confirm-Step 'Write PowerShell aliases/functions profile block?' $true)) {
    Write-PowerShellProfiles
}

Write-Host 'Coding Agents Windows Setup complete. Open a new PowerShell session to use updated aliases and PATH.'
