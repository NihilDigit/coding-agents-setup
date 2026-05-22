# BEGIN Coding Agents ergonomics
$__agentExtraPaths = @(
    (Join-Path $HOME 'AppData\Local\Microsoft\WinGet\Links'),
    (Join-Path $HOME 'scoop\shims'),
    (Join-Path $HOME '.bun\bin'),
    (Join-Path $HOME '.kimi-webbridge\bin'),
    'C:\Program Files\bottom\bin'
)
$__agentPathParts = $env:Path -split ';'
foreach ($__agentPath in $__agentExtraPaths) {
    if ($__agentPath -and (Test-Path -LiteralPath $__agentPath) -and ($__agentPathParts -notcontains $__agentPath)) {
        $env:Path += ";$__agentPath"
    }
}
Remove-Variable __agentExtraPaths, __agentPathParts, __agentPath -ErrorAction SilentlyContinue

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

Remove-Item Alias:ls,Alias:ll,Alias:la -Force -ErrorAction SilentlyContinue
function global:ls { eza --icons=auto @args }
function global:ll { eza --icons=auto -la @args }
function global:la { eza --icons=auto -a @args }

# Keep native cat/ps/diff aliases intact for scripts that expect PowerShell objects.
Set-Alias -Name bcat -Value bat -Option AllScope -Scope Global -Force
Set-Alias -Name grep -Value rg -Option AllScope -Scope Global -Force
Set-Alias -Name find -Value fd -Option AllScope -Scope Global -Force
Set-Alias -Name du -Value dust -Option AllScope -Scope Global -Force
Set-Alias -Name df -Value duf -Option AllScope -Scope Global -Force
Set-Alias -Name pps -Value procs -Option AllScope -Scope Global -Force
Set-Alias -Name top -Value btm -Option AllScope -Scope Global -Force
Set-Alias -Name bdiff -Value delta -Option AllScope -Scope Global -Force
Set-Alias -Name cp -Value Copy-Item -Option AllScope -Scope Global -Force
Set-Alias -Name mv -Value Move-Item -Option AllScope -Scope Global -Force
Set-Alias -Name kill -Value Stop-Process -Option AllScope -Scope Global -Force
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias -Name vi -Value nvim -Option AllScope -Scope Global -Force
    Set-Alias -Name vim -Value nvim -Option AllScope -Scope Global -Force
}

Remove-Item Alias:rm -Force -ErrorAction SilentlyContinue
function global:rm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Path,
        [switch]$Recurse,
        [switch]$Force
    )
    if (Get-Command trash -ErrorAction SilentlyContinue) {
        $trashArgs = @()
        if ($VerbosePreference -ne 'SilentlyContinue') { $trashArgs += '--verbose' }
        $trashArgs += foreach ($p in $Path) {
            if (Test-Path -LiteralPath $p) {
                (Resolve-Path -LiteralPath $p).ProviderPath -replace '\\', '/'
            } else {
                $p -replace '\\', '/'
            }
        }
        trash @trashArgs
        return
    }
    foreach ($p in $Path) {
        foreach ($resolved in Resolve-Path -Path $p -ErrorAction Stop) {
            $item = Get-Item -LiteralPath $resolved.Path -Force:$Force
            if ($item.PSIsContainer) {
                if (-not $Recurse) {
                    throw "Cannot remove directory '$($item.FullName)' without -Recurse."
                }
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($item.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin')
            } else {
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($item.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin')
            }
        }
    }
}

function global:which { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Name) Get-Command @Name }
function global:touch { param([Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)][string[]]$Path) foreach ($p in $Path) { if (Test-Path -LiteralPath $p) { (Get-Item -LiteralPath $p).LastWriteTime = Get-Date } else { New-Item -ItemType File -Path $p -Force | Out-Null } } }
function global:open { param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Path) foreach ($p in $Path) { Start-Process $p } }
function global:head { param([Parameter(Mandatory=$true)][string]$Path, [int]$n = 10) Get-Content -LiteralPath $Path -TotalCount $n }
function global:tail { param([Parameter(Mandatory=$true)][string]$Path, [int]$n = 10, [switch]$f) if ($f) { Get-Content -LiteralPath $Path -Tail $n -Wait } else { Get-Content -LiteralPath $Path -Tail $n } }
function global:less { if (Get-Command bat -ErrorAction SilentlyContinue) { bat --paging=always @args } else { more @args } }
function global:wc { param([Parameter(Mandatory=$true)][string]$Path, [switch]$l, [switch]$w, [switch]$c) $content = Get-Content -LiteralPath $Path; if ($l) { $content.Count } elseif ($w) { ($content | Measure-Object -Word).Words } elseif ($c) { ($content | Measure-Object -Character).Characters } else { [pscustomobject]@{ Lines = $content.Count; Words = ($content | Measure-Object -Word).Words; Chars = ($content | Measure-Object -Character).Characters } } }
function global:uptime { $os = Get-CimInstance Win32_OperatingSystem; $span = (Get-Date) - $os.LastBootUpTime; 'up {0}d {1}h {2}m' -f $span.Days, $span.Hours, $span.Minutes }
function global:pkill { param([Parameter(Mandatory=$true)][string]$Name) Get-Process -Name $Name -ErrorAction SilentlyContinue | Stop-Process -Force }

if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --follow --exclude .git'
}
# END Coding Agents ergonomics
