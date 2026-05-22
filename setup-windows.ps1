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
$SetupState = [ordered]@{
    GeneratedAt = (Get-Date).ToString('o')
    Agent = $null
    SkipTools = [bool]$SkipTools
    SkipProfile = [bool]$SkipProfile
    SelectedCommands = @()
    SelectedFeatures = @()
    ProfileSelected = $false
    UnixAliasesSelected = $false
}

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

function Add-SelectedCommand {
    param([Parameter(Mandatory = $true)][string[]]$Name)
    $SetupState.SelectedCommands = @($SetupState.SelectedCommands + $Name | Select-Object -Unique)
}

function Add-SelectedFeature {
    param([Parameter(Mandatory = $true)][string[]]$Name)
    $SetupState.SelectedFeatures = @($SetupState.SelectedFeatures + $Name | Select-Object -Unique)
}

function Write-SetupState {
    $stateDir = Join-Path $HOME '.coding-agents-setup'
    $statePath = Join-Path $stateDir 'windows-selection.json'
    New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
    $backup = Backup-Path $statePath
    if ($backup) { Write-Host "Backed up $statePath -> $backup" }
    $SetupState.GeneratedAt = (Get-Date).ToString('o')
    $SetupState | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $statePath -Encoding UTF8
    Write-Host "Wrote $statePath"
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
    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }
    if (($env:Path -split ';') -notcontains $Path) {
        $env:Path += ";$Path"
    }
    if ($env:GITHUB_PATH) {
        Add-Content -LiteralPath $env:GITHUB_PATH -Value $Path
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

    if (-not (Test-Command $Command)) {
        $roots = @(
            (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'),
            $env:ProgramFiles,
            ${env:ProgramFiles(x86)}
        ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

        foreach ($root in $roots) {
            $exe = Get-ChildItem -LiteralPath $root -Recurse -Filter "$Command.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($exe) {
                Add-SessionPath $exe.DirectoryName
                break
            }
        }
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
            Move-Item -LiteralPath $claudeSkills -Destination ($claudeSkills + '.old-' + (Get-Date -Format 'yyyyMMddHHmmss')) -Force
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

function Install-Rtk {
    if (Test-Command rtk) {
        try {
            rtk gain *> $null
            Write-Host 'RTK appears to be installed.'
            return
        } catch {
            Write-Warning 'A command named rtk exists, but it does not behave like rtk-ai/rtk.'
        }
    }
    Write-Warning 'This downloads the current rtk-ai/rtk Windows release from GitHub and installs rtk.exe to ~/.local/bin.'
    $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/rtk-ai/rtk/releases/latest'
    $asset = $release.assets | Where-Object { $_.name -eq 'rtk-x86_64-pc-windows-msvc.zip' } | Select-Object -First 1
    if (-not $asset) {
        throw 'Could not find rtk-x86_64-pc-windows-msvc.zip in the latest rtk-ai/rtk release.'
    }

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ('rtk-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $tempDir | Out-Null
    $zipPath = Join-Path $tempDir 'rtk.zip'
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
    Expand-Archive -LiteralPath $zipPath -DestinationPath $tempDir -Force
    $rtkExe = Get-ChildItem -LiteralPath $tempDir -Recurse -Filter 'rtk.exe' | Select-Object -First 1
    if (-not $rtkExe) {
        throw 'Downloaded RTK archive did not contain rtk.exe.'
    }

    $binDir = Join-Path $HOME '.local\bin'
    New-Item -ItemType Directory -Force -Path $binDir | Out-Null
    $targetRtk = Join-Path $binDir 'rtk.exe'
    $backup = Backup-Path $targetRtk
    if ($backup) { Write-Host "Backed up $targetRtk -> $backup" }
    Copy-Item -LiteralPath $rtkExe.FullName -Destination $targetRtk -Force
    Add-SessionPath $binDir

    & $targetRtk gain *> $null
    if ($LASTEXITCODE -ne 0) {
        throw 'Installed rtk.exe, but rtk gain failed.'
    }
}

function Write-PowerShellProfiles {
    param([bool]$IncludeUnixAliases = $true)

    $profileBlockPath = Join-Path $ScriptRoot 'profiles\Microsoft.PowerShell_profile.block.ps1'
    if (-not (Test-Path -LiteralPath $profileBlockPath)) { throw "Missing profile block: $profileBlockPath" }
    $profileBlock = (Get-Content -LiteralPath $profileBlockPath -Raw).TrimEnd()
    $aliasBlock = ''
    if ($IncludeUnixAliases) {
        $aliasBlockPath = Join-Path $ScriptRoot 'profiles\Microsoft.PowerShell_profile.aliases.ps1'
        if (-not (Test-Path -LiteralPath $aliasBlockPath)) { throw "Missing profile alias block: $aliasBlockPath" }
        $aliasBlock = (Get-Content -LiteralPath $aliasBlockPath -Raw).TrimEnd()
    }

    $profiles = @(
        (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
        (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1')
    )

    foreach ($profilePath in $profiles) {
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $profilePath) | Out-Null
        $content = if (Test-Path -LiteralPath $profilePath) { Get-Content -LiteralPath $profilePath -Raw } else { '' }
        $backup = Backup-Path $profilePath
        if ($backup) { Write-Host "Backed up $profilePath -> $backup" }
        $content = [regex]::Replace($content, '(?s)\r?\n?# BEGIN (Codex CLI|Coding Agents) ergonomics.*?# END (Codex CLI|Coding Agents) ergonomics\r?\n?', "`n")
        $content = [regex]::Replace($content, '(?s)\r?\n?# BEGIN Coding Agents Unix aliases.*?# END Coding Agents Unix aliases\r?\n?', "`n")
        $content = $content.TrimEnd()
        $blocks = @($profileBlock)
        if ($aliasBlock) { $blocks += $aliasBlock }
        $newBlock = $blocks -join "`n`n"
        $newContent = if ($content) { $content + "`n`n" + $newBlock + "`n" } else { $newBlock + "`n" }
        Set-TextFileLf -Path $profilePath -Text $newContent
        Write-Host "Wrote $profilePath"
    }
}

Write-Host 'Coding Agents Windows Setup'
$targetAgent = Select-AgentTarget
$SetupState.Agent = $targetAgent

if ($targetAgent -ne 'None') {
    Add-SelectedFeature 'agent-rules'
    Write-AgentRules -Target $targetAgent
}

if (-not $SkipTools) {
    if (Confirm-Step 'Ensure Git is installed?' $true) {
        Add-SelectedCommand 'git'
        Install-WinGetPackage -Id 'Git.Git' -Command 'git' -DisplayName 'Git'
    }

    if (Confirm-Step 'Install GitHub CLI (gh)? Useful for authenticated GitHub workflows.' $false) {
        Add-SelectedCommand 'gh'
        Install-WinGetPackage -Id 'GitHub.cli' -Command 'gh' -DisplayName 'GitHub CLI'
    }

    if (Confirm-Step 'Ensure uv is installed?' $true) {
        Add-SelectedCommand @('uv', 'uvx')
        Install-WinGetPackage -Id 'astral-sh.uv' -Command 'uv' -DisplayName 'uv'
    }

    if (Confirm-Step 'Ensure Bun is installed?' $true) {
        Add-SelectedCommand @('bun', 'bunx')
        Install-WinGetPackage -Id 'Oven-sh.Bun' -Command 'bun' -DisplayName 'Bun'
    }

    Add-SessionPath (Join-Path $HOME 'AppData\Local\Microsoft\WinGet\Links')
    Add-SessionPath (Join-Path $HOME '.bun\bin')
    Add-SessionPath (Join-Path $HOME 'scoop\shims')
    Add-SessionPath 'C:\Program Files\bottom\bin'

    if (Confirm-Step 'Install Codex CLI with bun if missing?' ($targetAgent -eq 'Codex' -or $targetAgent -eq 'Both')) {
        Add-SelectedCommand 'codex'
        Install-BunGlobal -Package '@openai/codex' -Command 'codex' -DisplayName 'Codex CLI'
    }

    if (Confirm-Step 'Install cross-platform trash CLI with bun if missing?' $true) {
        Add-SelectedCommand 'trash'
        Install-BunGlobal -Package 'trash-cli' -Command 'trash' -DisplayName 'trash-cli'
    }

    if (Confirm-Step 'Install RTK output-compaction CLI if missing?' $true) {
        Add-SelectedCommand 'rtk'
        Install-Rtk
    }

    if (Confirm-Step 'Install modern CLI tools (eza, zoxide, bat, rg, fd, fzf, jq, dust, duf, procs, bottom, delta)?' $true) {
        Add-SelectedCommand @('eza', 'zoxide', 'bat', 'rg', 'fd', 'fzf', 'jq', 'dust', 'duf', 'procs', 'btm', 'delta')
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
        Add-SelectedFeature 'skills-layout'
        Configure-SkillsLayout
    }

    if (Confirm-Step 'Install default Agent Skills (writing-style, impeccable)?' $true) {
        Add-SelectedFeature 'default-skills'
        Install-DefaultSkills
    }

    if (Confirm-Step 'Install Kimi WebBridge? Default yes; downloads and executes the current installer from kimi.com, and browser extension/profile access may be required for full automation.' $true) {
        Add-SelectedFeature 'kimi-webbridge'
        Install-KimiWebBridge
    }
}

if (-not $SkipProfile -and (Confirm-Step 'Write PowerShell aliases/functions profile block?' $true)) {
    $SetupState.ProfileSelected = $true
    $includeUnixAliases = Confirm-Step 'Enable recommended Unix-style PowerShell aliases, including safe rm-to-trash shadowing?' $true
    $SetupState.UnixAliasesSelected = $includeUnixAliases
    if ($includeUnixAliases) {
        Add-SelectedFeature 'windows-unix-aliases'
    }
    Write-PowerShellProfiles -IncludeUnixAliases $includeUnixAliases
}

Write-SetupState
Write-Host 'Coding Agents Windows Setup complete. Open a new PowerShell session to use updated aliases and PATH.'
