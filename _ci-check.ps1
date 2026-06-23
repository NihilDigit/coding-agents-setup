param(
    [string]$RunId = "28002992040"
)

$ErrorActionPreference = "Stop"
$url = "https://api.github.com/repos/NihilDigit/coding-agents-setup/actions/runs/$RunId/attempts/1/logs"
$zip = Join-Path $env:TEMP "ci-logs.zip"

Write-Host "Downloading logs..."
curl.exe -sL -o $zip $url 2>&1 | Out-Null

Add-Type -AssemblyName System.IO.Compression.FileSystem
$z = [System.IO.Compression.ZipFile]::OpenRead($zip)

foreach ($e in $z.Entries) {
    if ($e.Length -eq 0) { continue }
    $r = New-Object System.IO.StreamReader($e.Open())
    $c = $r.ReadToEnd()
    $r.Close()
    
    $lines = $c -split "`n"
    $errorLines = $lines | Where-Object { $_ -match '(?i)(error|failure|failed|exit code|fatal|exception|FAIL|✗|##\[error\])' }
    if ($errorLines) {
        Write-Host "=== $($e.Name) ===" -ForegroundColor Red
        foreach ($line in $errorLines) {
            $trimmed = $line.Trim()
            if ($trimmed.Length -gt 0) {
                Write-Host "  $($trimmed.Substring(0, [Math]::Min(400, $trimmed.Length)))"
            }
        }
    }
}
$z.Dispose()
Remove-Item $zip -Force -ErrorAction SilentlyContinue
