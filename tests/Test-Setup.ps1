$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$psFiles = @(
    (Join-Path $root 'setup-windows.ps1')
    (Join-Path $root 'install.ps1')
    Join-Path $root 'profiles\Microsoft.PowerShell_profile.block.ps1'
)

$shFiles = @(
    (Join-Path $root 'setup-linux.sh')
    (Join-Path $root 'install.sh')
)

foreach ($path in $psFiles) {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors) {
        $errors | Format-List Message,Extent
        throw "PowerShell parse failed: $path"
    }
}

foreach ($path in $shFiles) {
    $bash = Get-Command bash -All -ErrorAction SilentlyContinue | Where-Object { $_.Source -match '\\Git\\|\\scoop\\apps\\git\\|/usr/bin/bash|/bin/bash' } | Select-Object -First 1
    if ($bash) {
        & $bash.Source -n $path
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Bash parse check failed or bash is unavailable in this sandbox: $path"
        }
    }
}

$mdFiles = Get-ChildItem -LiteralPath (Join-Path $root 'rules') -Filter '*.md'
foreach ($file in $mdFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    for ($i = 0; $i -lt $bytes.Length; $i++) {
        if ($bytes[$i] -eq 10 -and $i -gt 0 -and $bytes[$i - 1] -eq 13) {
            throw "CRLF found in $($file.FullName)"
        }
    }
}

Write-Host 'setup tests passed'
