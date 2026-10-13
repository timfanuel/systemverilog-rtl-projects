onerror {quit -code 1 -f}
onbreak {resume}
file mkdir build
if {![file exists build/lib]} {vlib build/lib}
transcript file build/compile.log
vlog -sv -work build/lib rtl/sync_fifo.sv tb/sync_fifo_tb.sv tb/sync_fifo_regression_tb.sv
foreach config {{1 1} {8 2} {8 10} {32 16} {128 256}} {
    lassign $config width depth
    foreach seed {1 42} {
        transcript file build/w${width}_d${depth}_s${seed}.log
        vsim -onfinish stop -voptargs=+acc -lib build/lib -gDATA_WIDTH=$width -gDEPTH=$depth -gSEED=$seed sync_fifo_regression_tb
        if {$width==8 && $depth==10 && $seed==1} {
            vcd file build/sync_fifo.vcd
            vcd add /sync_fifo_regression_tb/clk /sync_fifo_regression_tb/rst /sync_fifo_regression_tb/wr_en /sync_fifo_regression_tb/rd_en /sync_fifo_regression_tb/wr_data /sync_fifo_regression_tb/rd_data /sync_fifo_regression_tb/full /sync_fifo_regression_tb/empty /sync_fifo_regression_tb/dut/count
        }
        run 300 us
        if {$width==8 && $depth==10 && $seed==1} {vcd flush}
        quit -sim
    }
}
transcript file build/original_tb.log
vsim -onfinish stop -lib build/lib sync_fifo_tb
run 300 us
quit -sim
quit -code 0 -f
