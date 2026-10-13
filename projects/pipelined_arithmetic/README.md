# Pipelined Add–Multiply Datapath

A two-stage unsigned arithmetic pipeline computing **`(a + b) * c`**, with ready/valid flow control and consumer backpressure. The existing module name is `pipelined_mac`; there is no accumulator or feedback path.

## Design

- `WIDTH` defaults to 8. Inputs `a`, `b`, and `c` are unsigned `WIDTH`-bit values.
- Stage 1 registers an explicitly widened `WIDTH+1`-bit sum and the matching `c` operand. This preserves the carry from `a+b`.
- Stage 2 registers the product in `2*WIDTH+1` bits, enough for the unsigned full result.
- Each stage loads when empty or when its word advances. Ready propagates backward, allowing one transaction per cycle after fill when the consumer is ready.
- Reset is synchronous, active high, and clears valid flags. Data registers are not reset; output data is meaningful only when `out_valid` is asserted. Buffered work is discarded on reset.
- The producer holds `a`, `b`, `c`, and `in_valid` until a rising-edge transfer with `in_ready`. The consumer accepts results on a rising edge with both `out_valid` and `out_ready` asserted. Reset has priority over transfers.

The stages isolate addition and multiplication into separate clock intervals. This is a single-clock RTL datapath; no FPGA DSP mapping, timing closure, or hardware implementation is claimed.

## Files and provenance

| File | Role |
| --- | --- |
| `rtl/pipelined_mac.sv` | Existing RTL, copied from `pipelined_mac_fixed.sv` without content changes |
| `tb/pipelined_mac_tb.sv` | Existing directed testbench |
| `tb/pipelined_mac_tb_randomized.sv` | Existing randomized transaction scoreboard |
| `sim/run.do`, `sim/run.ps1` | Added checked simulation entry points |
| `reports/` | Actual local simulation transcripts and review status |

Original RTL and testbench contents are preserved. A separate ModelSim-folder version was found; this package uses the FPGA-folder version and does not merge those copies. The owner explicitly approved adding this arithmetic project to the public portfolio. No third-party source notice or applicable course-sharing policy was found in the selected files; original authorship was not independently established. No license was selected automatically.

## Actual verification

Executed with ModelSim Intel FPGA Starter Edition 10.5b on October 12, 2026:

| Test | Configuration | Actual result |
| --- | --- | --- |
| Directed | WIDTH=8 | Results 20, 60, 27 matched `(2+3)*4`, `(5+1)*10`, `(7+2)*3`, including a consumer stall |
| Randomized | WIDTH=8, NUM_CYCLES=10000 | 4025 inputs accepted, 4025 outputs checked, 0 errors, empty final queue; `RANDOMIZED TEST PASSED` |

The randomized producer retains blocked operands and drives stimulus on falling edges. The scoreboard compares accepted output values against queued arithmetic results and checks final accounting after draining.

Limitations: this run tested only width 8 and the simulator's default random seed. The existing expected-result function uses 32-bit integer arithmetic, so it is not a reliable full-precision oracle for wider configurations whose products exceed 32 bits. There is no procedural/concurrent output-stability check, exhaustive arithmetic boundary suite, formal proof, or reset-while-occupied test. No synthesis reports were found for this particular datapath, and no new synthesis or board test was performed. Existing testbenches use `$stop`; the scripts handle it and check the transcript rather than trusting the simulator exit code alone.

## Reproduce

Requirements: PowerShell and ModelSim/Questa with SystemVerilog support; put `vsim`, `vlog`, and `vlib` on PATH, or specify the simulator executable:

```powershell
./sim/run.ps1
# Inspected local installation:
./sim/run.ps1 -Simulator 'C:\intelFPGA\18.1\modelsim_ase\win32aloem\vsim.exe'
```

Generated output goes into ignored `build/`. The wrapper rejects error/fatal diagnostics, requires all three directed PASS messages and the randomized success marker, and verifies randomized accounting. Other simulators were not tested.
