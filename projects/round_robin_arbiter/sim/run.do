onerror {quit -code 1 -f}
onbreak {resume}
file mkdir build
if {![file exists build/lib]} {vlib build/lib}
transcript file build/compile.log
vlog -sv -work build/lib rtl/round_robin_arbiter.sv tb/round_robin_arbiter_tb.sv
foreach seed {1 42 2026} {
    transcript file build/seed${seed}.log
    vsim -onfinish stop -voptargs=+acc -lib build/lib -gSEED=$seed round_robin_arbiter_tb
    if {$seed==1} {
        vcd file build/round_robin_arbiter.vcd
        vcd add /round_robin_arbiter_tb/clk /round_robin_arbiter_tb/rst /round_robin_arbiter_tb/req /round_robin_arbiter_tb/grant /round_robin_arbiter_tb/dut/last_grant
    }
    run 150 us
    if {$seed==1} {vcd flush}
    quit -sim
}
quit -code 0 -f
