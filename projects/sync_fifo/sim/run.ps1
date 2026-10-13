param([string]$Simulator='vsim')
$ErrorActionPreference='Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & $Simulator -c -do sim/run.do
    if($LASTEXITCODE -ne 0) { throw "Simulator exit code $LASTEXITCODE" }
    foreach($config in @(@(1,1),@(8,2),@(8,10),@(32,16),@(128,256))) {
        $width=$config[0]; $depth=$config[1]
        foreach($seed in 1,42) {
            $log=Get-Content "build/w${width}_d${depth}_s${seed}.log" -Raw
            if($log -match '\*\* (Error|Fatal):' -or $log -notmatch "PASS FIFO width=$width depth=$depth seed=$seed " -or $log -notmatch '\*\* Note: \$finish') {
                throw "FIFO regression failure: width=$width depth=$depth seed=$seed"
            }
        }
    }
    $original=Get-Content build/original_tb.log -Raw
    if($original -match '\*\* (Error|Fatal):' -or $original -notmatch 'FIFO RANDOM TEST SUMMARY' -or $original -notmatch '\*\* Note: \$finish') { throw 'Original test failed or did not complete' }
    Write-Output 'PASS: ten FIFO regressions and original scoreboard completed; original SVA/coverage unsupported by Starter.'
} finally { Pop-Location }
