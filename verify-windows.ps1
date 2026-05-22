param(
    [string]$StatePath = (Join-Path $HOME '.coding-agents-setup\windows-selection.json'),
    [switch]$Recommended
)

$ErrorActionPreference = 'Continue'

$failures = 0
$warnings = 0

function Ok {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "ok: $Message"
}

function Warn {
    param([Parameter(Mandatory = $true)][string]$Message)
    $script:warnings += 1
    Write-Warning $Message
}

function Fail {
    param([Parameter(Mandatory = $true)][string]$Message)
    $script:failures += 1
    Write-Host "fail: $Message" -ForegroundColor Red
}

function Require-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        Ok "$Name -> $($cmd.Source)"
    } else {
        Fail "missing command: $Name"
    }
}

function Recommend-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) {
        Ok "$Name -> $($cmd.Source)"
    } else {
        Warn "missing recommended command: $Name"
    }
}

function Check-File {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        Ok "$Path exists"
    } else {
        Fail "$Path is missing"
    }
}

function Check-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Pattern,
        [Parameter(Mandatory = $true)][string]$Label
    )
    if ((Test-Path -LiteralPath $Path -PathType Leaf) -and ((Get-Content -LiteralPath $Path -Raw) -like "*$Pattern*")) {
        Ok $Label
    } else {
        Fail $Label
    }
}

Write-Host 'Coding Agents Windows verification'
Write-Host "PowerShell: $($PSVersionTable.PSVersion)"

$state = $null
if (Test-Path -LiteralPath $StatePath -PathType Leaf) {
    try {
        $state = Get-Content -LiteralPath $StatePath -Raw | ConvertFrom-Json
        Ok "loaded setup selection state: $StatePath"
    } catch {
        Warn "could not parse setup selection state: $StatePath"
    }
} else {
    Warn "setup selection state not found: $StatePath"
}

if ($state) {
    foreach ($cmd in @($state.SelectedCommands)) {
        Require-Command $cmd
    }
} else {
    foreach ($cmd in @('git', 'bun', 'bunx', 'uv', 'uvx', 'trash', 'rtk')) {
        Require-Command $cmd
    }
}

if ($Recommended) {
    foreach ($cmd in @('eza', 'zoxide', 'bat', 'rg', 'fd', 'fzf', 'jq', 'dust', 'duf', 'procs', 'btm', 'delta', 'kimi-webbridge')) {
        Recommend-Command $cmd
    }
}

if (Get-Command rtk -ErrorAction SilentlyContinue) {
    & rtk gain *> $null
    if ($LASTEXITCODE -eq 0) {
        Ok 'rtk gain works; expected rtk-ai/rtk behavior'
    } else {
        Fail 'rtk exists but rtk gain failed; check for wrong rtk package'
    }
}

if (Get-Command trash -ErrorAction SilentlyContinue) {
    $trashSource = (Get-Command trash).Source
    if ($trashSource -like '*\.bun\*' -or $trashSource -like '*node_modules*') {
        Ok 'trash appears to come from bun/npm trash-cli'
    } else {
        Warn "trash source is not bun/npm-looking: $trashSource"
    }
}

if ((-not $state) -or ($state.Agent -eq 'Codex') -or ($state.Agent -eq 'Both')) {
    $codexRules = Join-Path $HOME '.codex\AGENTS.md'
    Check-File $codexRules
    Check-Contains $codexRules '# Windows Environment' 'Codex rules include Windows fragment'
}

if ((-not $state) -or ($state.Agent -eq 'Claude') -or ($state.Agent -eq 'Both')) {
    $claudeRules = Join-Path $HOME '.claude\CLAUDE.md'
    Check-File $claudeRules
    Check-Contains $claudeRules '# Windows Environment' 'Claude rules include Windows fragment'
}

if ($state -and (@($state.SelectedFeatures) -contains 'skills-layout')) {
    $agentsSkills = Join-Path $HOME '.agents\skills'
    $claudeSkills = Join-Path $HOME '.claude\skills'
    if (Test-Path -LiteralPath $agentsSkills -PathType Container) {
        Ok "$agentsSkills exists"
    } else {
        Fail "$agentsSkills is missing"
    }
    if (Test-Path -LiteralPath $claudeSkills) {
        Ok "$claudeSkills exists"
    } else {
        Fail "$claudeSkills is missing"
    }
}

if ($state -and (@($state.SelectedFeatures) -contains 'default-skills')) {
    foreach ($skill in @('writing-style', 'impeccable')) {
        $skillPath = Join-Path $HOME ".agents\skills\$skill"
        if (Test-Path -LiteralPath $skillPath) {
            Ok "$skill skill exists"
        } else {
            Fail "$skill skill is missing"
        }
    }
}

$profilePaths = @(
    (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1'),
    (Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1')
)
if ((-not $state) -or $state.ProfileSelected) {
    foreach ($profilePath in $profilePaths) {
        if ((Test-Path -LiteralPath $profilePath -PathType Leaf) -and ((Get-Content -LiteralPath $profilePath -Raw) -like '*# BEGIN Coding Agents ergonomics*')) {
            Ok "$profilePath contains Coding Agents profile block"
        } else {
            Fail "$profilePath does not contain Coding Agents profile block"
        }
    }
}

Write-Host ''
Write-Host "summary: $failures failure(s), $warnings warning(s)"
if ($failures -gt 0) {
    exit 1
}
