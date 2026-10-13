param([string]$Simulator = 'vsim')
$ErrorActionPreference = 'Stop'
Push-Location (Split-Path $PSScriptRoot -Parent)
try {
    & $Simulator -c -do sim/run.do
    if ($LASTEXITCODE -ne 0) { throw "Simulator exited with code $LASTEXITCODE" }
    foreach ($top in 'uart_tx_tb','uart_tx_tb_extended','uart_rx_tb','uart_loopback_tb','rx_edges_tb','tx_all_bytes_tb') {
        $log = Get-Content "build/$top.log" -Raw
        if ($log -match '\*\* (Error|Fatal):' -or $log -notmatch '\*\* Note: \$(finish|stop)') {
            throw "Failure or missing completion: $top"
        }
    }
    $rx = Get-Content build/rx_edges_tb.log -Raw
    $tx = Get-Content build/tx_all_bytes_tb.log -Raw
    if ($rx -notmatch 'PASS RX_EDGES valid_frames=3' -or $tx -notmatch 'PASS TX_ALL_BYTES frames=256') { throw 'Missing regression pass marker' }
    Write-Output 'PASS: UART checked tests completed; basic TX smoke completed.'
} finally { Pop-Location }
