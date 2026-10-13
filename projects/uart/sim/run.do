onerror {quit -code 1 -f}
onbreak {resume}
file mkdir build
if {![file exists build/lib]} {vlib build/lib}
transcript file build/compile.log
vlog -sv -work build/lib rtl/uart_tx.sv rtl/uart_rx.sv rtl/uart.sv tb/uart_tx_tb.sv tb/uart_tx_tb2.sv tb/uart_rx_tb.sv tb/uart_loopback_tb.sv tb/rx_edges_tb.sv tb/tx_all_bytes_tb.sv
foreach top {uart_tx_tb uart_tx_tb_extended uart_rx_tb uart_loopback_tb rx_edges_tb tx_all_bytes_tb} {
    transcript file build/${top}.log
    vsim -onfinish stop -voptargs=+acc -lib build/lib $top
    if {$top == "tx_all_bytes_tb"} {
        vcd file build/uart_tx.vcd
        vcd add /tx_all_bytes_tb/clk /tx_all_bytes_tb/rst /tx_all_bytes_tb/tx_data /tx_all_bytes_tb/tx_valid /tx_all_bytes_tb/tx_ready /tx_all_bytes_tb/tx_serial
    }
    run 300 us
    if {$top == "tx_all_bytes_tb"} {vcd flush}
    quit -sim
}
quit -code 0 -f
