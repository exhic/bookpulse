$ErrorActionPreference = "Continue"
Set-Location "c:\Users\han\hiccup\claude_cowork\bookpulse_starter"

$logDir = "scripts\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile = "$logDir\generate-$(Get-Date -Format 'yyyyMMdd').log"

"=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') BookPulse daily generate 시작 ===" | Out-File -FilePath $logFile -Append -Encoding utf8

claude -p "/bookpulse-generate" --permission-mode acceptEdits *>> $logFile

"=== $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 종료 ===" | Out-File -FilePath $logFile -Append -Encoding utf8
