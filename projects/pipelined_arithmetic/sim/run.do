onerror {quit -code 1 -f}
onbreak {resume}
file mkdir build
if {![file exists build/lib]} {vlib build/lib}
transcript file build/compile.log
vlog -sv -work build/lib rtl/pipelined_mac.sv tb/pipelined_mac_tb.sv tb/pipelined_mac_tb_randomized.sv
transcript file build/directed.log
vsim -lib build/lib pipelined_mac_tb
run 2 us
quit -sim
transcript file build/randomized.log
vsim -lib build/lib -gNUM_CYCLES=10000 pipelined_mac_random_tb
run 200 us
quit -sim
quit -code 0 -f
