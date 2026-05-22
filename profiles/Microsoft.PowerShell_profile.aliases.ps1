# BEGIN Coding Agents Unix aliases
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
# END Coding Agents Unix aliases
