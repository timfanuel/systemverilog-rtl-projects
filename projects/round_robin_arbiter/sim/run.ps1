param([string]$Simulator='vsim')
$ErrorActionPreference='Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & $Simulator -c -do sim/run.do
    if($LASTEXITCODE -ne 0) { throw "Simulator exit code $LASTEXITCODE" }
    foreach($seed in 1,42,2026) {
        $log=Get-Content "build/seed${seed}.log" -Raw
        if($log -match '\*\* (Error|Fatal):' -or $log -notmatch "PASS ARBITER seed=$seed " -or $log -notmatch 'priority_request_pairs=64' -or $log -notmatch '\*\* Note: \$finish') {
            throw "Arbiter regression failed or incomplete: seed=$seed"
        }
    }
    Write-Output 'PASS: all three arbiter regression seeds completed, each covering 64 priority/request combinations.'
} finally { Pop-Location }
