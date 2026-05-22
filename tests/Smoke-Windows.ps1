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

foreach ($cmd in @('git', 'uv', 'uvx', 'bun', 'bunx', 'trash', 'rtk')) {
    Require-Command $cmd
}

git --version *> $null
uv --version *> $null
uvx --version *> $null
bun --version *> $null
bunx --version *> $null
trash --help *> $null
rtk gain *> $null
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

if ($state -and (@($state.SelectedFeatures) -contains 'kimi-webbridge')) {
    $kimi = Get-Command kimi-webbridge -ErrorAction SilentlyContinue
    if (-not $kimi) {
        $kimi = Get-Command webbridge -ErrorAction SilentlyContinue
    }
    if (-not $kimi) {
        throw 'Kimi WebBridge was selected but no command is available'
    }

    $statusOk = $false
    for ($i = 0; $i -lt 3; $i++) {
        try {
            Invoke-ExternalWithTimeout -FilePath $kimi.Source -ArgumentList @('status') -TimeoutSeconds 15 -Label 'Kimi WebBridge status'
            $statusOk = $true
            break
        } catch {
            Write-Warning $_.Exception.Message
        }
        Start-Sleep -Seconds 2
    }
    if (-not $statusOk) {
        throw 'Kimi WebBridge status did not succeed after installation'
    }
    Ok 'Kimi WebBridge status succeeds'
}

pwsh -NoLogo -NoProfile -File (Join-Path $root 'verify-windows.ps1')
if ($LASTEXITCODE -ne 0) {
    throw "verify-windows failed after behavior smoke with exit code $LASTEXITCODE"
}

Write-Host 'Windows behavior smoke passed'
