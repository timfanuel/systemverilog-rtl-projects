# Simulation results

Run date: October 12, 2026 (America/Los_Angeles). Simulator: ModelSim Intel FPGA Starter Edition 10.5b. Command: `./sim/run.ps1 -Simulator 'C:\intelFPGA\18.1\modelsim_ase\win32aloem\vsim.exe'`.

| Width | Seed | Accepted | Delivered | Flushed by reset | Output stall cycles | Maximum consecutive output transfers | Result |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 4071 | 4069 | 2 | 3941 | 32 | PASS |
| 1 | 42 | 4062 | 4060 | 2 | 4063 | 32 | PASS |
| 1 | 2026 | 4001 | 3999 | 2 | 4132 | 32 | PASS |
| 8 | 1 | 4071 | 4069 | 2 | 3941 | 32 | PASS |
| 8 | 42 | 4062 | 4060 | 2 | 4063 | 32 | PASS |
| 8 | 2026 | 4001 | 3999 | 2 | 4132 | 32 | PASS |
| 32 | 1 | 4071 | 4069 | 2 | 3941 | 32 | PASS |
| 32 | 42 | 4062 | 4060 | 2 | 4063 | 32 | PASS |
| 32 | 2026 | 4001 | 3999 | 2 | 4132 | 32 | PASS |

Matching counts across widths reflect identical control stimulus, with payloads truncated to each width. Accepted = delivered + flushed in every run. Each configuration uses 10,000 pseudorandom cycles plus directed stimulus. All added regression runs reported zero errors and zero warnings.

The preserved original testbench completed with 3775 accepted, 3775 delivered, reported stall_count 3751, and final queue size 0. It reported no errors but warned that SystemVerilog assertions require Questa. The original concurrent stall assertion was skipped. Compiler warnings also flag testbench features unsupported by this edition. Its reported stall count uses its own sampling convention; it is not directly comparable to the new regression's count.

The raw logs are beside this document, including compiler diagnostics. They are simulator transcripts copied from the actual run, not reconstructed outputs. The first lines of a log may contain the previous simulation's teardown because the transcript destination changes before each invocation.

## Limits

- No exhaustive/formal verification, coverage closure, or tests beyond widths 1, 8, 32 and the listed seeds.
- The original testbench has a reset-edge race and changes producer signals while blocked; it is preserved as legacy evidence. The added regression avoids these stimulus limitations.
- No other simulator was tested. No new synthesis, timing closure, board programming, or physical FPGA testing was performed.
- Missing FIFO and arbiter files were not simulated or included.
