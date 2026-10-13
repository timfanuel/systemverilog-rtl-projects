# Run from the repository root: vsim -c -do sim/run.do
onerror {quit -code 1 -f}
# $finish is a normal break with -onfinish stop; the PowerShell wrapper
# requires every PASS marker and rejects Error/Fatal diagnostics.
onbreak {resume}
file mkdir build
if {![file exists build/lib]} {vlib build/lib}
transcript file build/compile.log
vlog -sv -work build/lib rtl/rv_pipeline.sv tb/rv_pipeline_tb.sv tb/rv_pipeline_regression_tb.sv
foreach width {1 8 32} {
    foreach seed {1 42 2026} {
        transcript file build/width${width}_seed${seed}.log
        vsim -onfinish stop -voptargs=+acc -lib build/lib -gDATA_WIDTH=$width -gSEED=$seed rv_pipeline_regression_tb
        if {$width == 8 && $seed == 1} {
            vcd file build/rv_pipeline.vcd
            vcd add /rv_pipeline_regression_tb/clk /rv_pipeline_regression_tb/rst /rv_pipeline_regression_tb/in_valid /rv_pipeline_regression_tb/in_ready /rv_pipeline_regression_tb/in_data /rv_pipeline_regression_tb/out_valid /rv_pipeline_regression_tb/out_ready /rv_pipeline_regression_tb/out_data
        }
        run -all
        if {$width == 8 && $seed == 1} {vcd flush}
        quit -sim
    }
}
transcript file build/original_tb.log
vsim -onfinish stop -lib build/lib rv_pipeline_tb
run 200 us
quit -sim
quit -code 0 -f
