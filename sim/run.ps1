param([string]$Simulator = 'vsim')
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & $Simulator -c -do sim/run.do
    if ($LASTEXITCODE -ne 0) { throw "Simulator exited with code $LASTEXITCODE" }
    foreach ($width in 1, 8, 32) {
        foreach ($seed in 1, 42, 2026) {
            $log = Get-Content "build/width${width}_seed${seed}.log" -Raw
            if ($log -notmatch "PASS width=$width seed=$seed " -or $log -match '\*\* (Error|Fatal):') {
                throw "Regression failed: width=$width seed=$seed"
            }
        }
    }
    $original = Get-Content build/original_tb.log -Raw
    if ($original -match '\*\* (Error|Fatal):' -or $original -notmatch 'Final queue size:\s+0') {
        throw 'Original testbench did not complete cleanly'
    }
    Write-Output 'PASS: nine regression configurations and original scoreboard completed.'
} finally { Pop-Location }
