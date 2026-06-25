$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$statePath = Join-Path $HOME '.coding-agents-setup\windows-selection.json'
$state = if (Test-Path -LiteralPath $statePath -PathType Leaf) {
    Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
} else {
    $null
}

function Ok {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host "ok: $Message"
}

function Require-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $cmd) {
        throw "missing command: $Name"
    }
    Ok "$Name -> $($cmd.Source)"
}

function Invoke-ExternalWithTimeout {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][int]$TimeoutSeconds,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $process = Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -NoNewWindow -PassThru
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        throw "$Label timed out after $TimeoutSeconds seconds"
    }
    if ($process.ExitCode -ne 0) {
        throw "$Label failed with exit code $($process.ExitCode)"
    }
}

function Test-RtkCommand {
    $previousErrorActionPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $versionOutput = & rtk --version 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "rtk --version failed with exit code $LASTEXITCODE"
        }

        $helpOutput = & rtk --help 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "rtk --help failed with exit code $LASTEXITCODE"
        }

        $probeText = (@($versionOutput) + @($helpOutput)) -join "`n"
        if (-not (($probeText -match '(?m)^rtk\s+\d') -and ($probeText -like '*token-optimized output*'))) {
            throw 'rtk exists but does not look like rtk-ai/rtk'
        }
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
}

foreach ($cmd in @('git', 'uv', 'uvx', 'bun', 'bunx', 'trash', 'rtk')) {
    Require-Command $cmd
}

git --version *> $null
uv --version *> $null
uvx --version *> $null
bun --version *> $null
bunx --version *> $null
trash --help *> $null
Test-RtkCommand
Ok 'core commands execute'

$profileProbe = @'
$ErrorActionPreference = 'Stop'
$rmCommand = Get-Command rm -ErrorAction Stop
if ($rmCommand.CommandType -ne 'Function') {
    throw "rm was not shadowed by the Coding Agents profile; saw $($rmCommand.CommandType)"
}
$target = Join-Path $env:TEMP ('coding-agents-rm-shadow-' + [guid]::NewGuid().ToString('N') + '.txt')
Set-Content -LiteralPath $target -Value 'rm shadow smoke'
rm $target
if (Test-Path -LiteralPath $target) {
    throw "rm shadow did not move the temp file out of its original path"
}
if ((Get-Command trash -ErrorAction SilentlyContinue) -and ((Get-Command rm).Definition -notlike '*trash*')) {
    throw 'rm shadow is present but does not route through trash when trash is available'
}
'@

$profileProbePath = Join-Path $env:TEMP ('coding-agents-profile-smoke-' + [guid]::NewGuid().ToString('N') + '.ps1')
Set-Content -LiteralPath $profileProbePath -Value $profileProbe -Encoding UTF8
Invoke-ExternalWithTimeout -FilePath (Get-Command pwsh).Source -ArgumentList @('-NoLogo', '-File', $profileProbePath) -TimeoutSeconds 30 -Label 'fresh PowerShell profile behavior smoke'
Ok 'fresh PowerShell session loads rm-to-trash shadowing'

if ($state -and (@($state.SelectedFeatures) -contains 'agent-browser')) {
    $agentBrowser = Get-Command agent-browser -ErrorAction SilentlyContinue
    if (-not $agentBrowser) {
        throw 'agent-browser was selected but no command is available'
    }

    Invoke-ExternalWithTimeout -FilePath $agentBrowser.Source -ArgumentList @('--version') -TimeoutSeconds 15 -Label 'agent-browser version'

    $agentBrowserConfig = Join-Path $HOME '.agent-browser\config.json'
    if (-not (Test-Path -LiteralPath $agentBrowserConfig -PathType Leaf)) {
        throw 'agent-browser config is missing'
    }
    $config = Get-Content -LiteralPath $agentBrowserConfig -Raw | ConvertFrom-Json
    if (($config.headed -ne $true) -or ($config.profile -ne 'Default')) {
        throw 'agent-browser config does not use headed Default profile'
    }
    Ok 'agent-browser command and config are available'
}

# Test tag-conditional rule filtering
$filterTestContent = @'
# Common header

<!-- :windows-only -->
## Windows specific
Windows content
<!-- :end -->

<!-- :linux-only -->
## Linux specific
Linux content
<!-- :end -->

<!-- :codex-only -->
Codex browser content
<!-- :end -->

<!-- :claude-only :pi-only -->
Agent browser content
<!-- :end -->

## Shared footer
'@

function Convert-SmokeRuleTextForTags {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string[]]$ActiveTags
    )

    $active = @{}
    foreach ($tag in $ActiveTags) {
        $active[$tag.ToLowerInvariant()] = $true
    }

    $pattern = '(?ms)^[ \t]*<!--\s*((?::[a-z0-9-]+-only\s*)+)-->\r?\n?(.*?)^[ \t]*<!--\s*:end\s*-->\r?\n?'
    return [regex]::Replace($Text, $pattern, {
        param($match)
        $markers = [regex]::Matches($match.Groups[1].Value, ':([a-z0-9-]+)-only')
        foreach ($marker in $markers) {
            $tag = $marker.Groups[1].Value.ToLowerInvariant()
            if ($active.ContainsKey($tag)) {
                return $match.Groups[2].Value
            }
        }
        return ''
    })
}

$filtered = Convert-SmokeRuleTextForTags -Text $filterTestContent -ActiveTags @('windows', 'codex')
$filteredPi = Convert-SmokeRuleTextForTags -Text $filterTestContent -ActiveTags @('windows', 'pi')

if ($filtered -notmatch 'Windows specific') { throw 'Windows content was stripped on Windows' }
if ($filtered -match 'Linux specific') { throw 'Linux content was not stripped on Windows' }
if ($filtered -notmatch 'Codex browser content') { throw 'Codex content was stripped for Codex' }
if ($filtered -match 'Agent browser content') { throw 'Non-Codex agent browser content leaked into Codex output' }
if ($filteredPi -notmatch 'Agent browser content') { throw 'Multi-tag Pi content was stripped for Pi' }
if ($filteredPi -match 'Codex browser content') { throw 'Codex content leaked into Pi output' }
if ($filtered -match '<!-- :') { throw 'Conditional markers leaked through Codex filtering' }
if ($filteredPi -match '<!-- :') { throw 'Conditional markers leaked through Pi filtering' }
Ok 'tag-conditional rule filtering strips inactive blocks on Windows'

pwsh -NoLogo -NoProfile -File (Join-Path $root 'verify-windows.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "verify-windows failed after behavior smoke with exit code $LASTEXITCODE"
}

Write-Host 'Windows behavior smoke passed'
