param([string]$Simulator = 'vsim')
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & $Simulator -c -do sim/run.do
    if ($LASTEXITCODE -ne 0) { throw "Simulator exited with code $LASTEXITCODE" }
    $directed = Get-Content build/directed.log -Raw
    $randomized = Get-Content build/randomized.log -Raw
    if (($directed + $randomized) -match '\*\* (Error|Fatal):') { throw 'Simulation diagnostic failure' }
    foreach ($value in 20, 60, 27) {
        if ($directed -notmatch "PASS: Expected $value, got $value") { throw "Missing directed result $value" }
    }
    if ($randomized -notmatch 'RANDOMIZED TEST PASSED' -or $randomized -notmatch 'Errors\s+:\s+0' -or $randomized -notmatch 'Queue remaining\s+:\s+0') {
        throw 'Randomized test failed or did not complete'
    }
    $accepted = [regex]::Match($randomized, 'Inputs accepted\s+:\s+(\d+)')
    $checked = [regex]::Match($randomized, 'Outputs checked\s+:\s+(\d+)')
    if (!$accepted.Success -or !$checked.Success -or $accepted.Groups[1].Value -ne $checked.Groups[1].Value) { throw 'Accounting mismatch' }
    Write-Output 'PASS: directed and randomized arithmetic simulations completed.'
} finally { Pop-Location }
