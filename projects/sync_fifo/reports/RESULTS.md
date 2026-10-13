# Actual FIFO simulation results

Executed October 13, 2026 with ModelSim Intel FPGA Starter Edition 10.5b using `sim/run.ps1`. Ten procedural regressions passed, with zero errors/warnings, plus the preserved original scoreboard completed without errors but with unsupported-feature warnings.

| Width | Depth | Seed | Writes | Reads | Simultaneous accepted | Reset-discarded | Blocked writes | Blocked reads | Final queue |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 1 | 1 | 2522 | 2521 | 0 | 1 | 2540 | 2551 | 0 |
| 1 | 1 | 42 | 2509 | 2508 | 0 | 1 | 2547 | 2414 | 0 |
| 8 | 2 | 1 | 3779 | 3777 | 1227 | 2 | 1289 | 1301 | 0 |
| 8 | 2 | 42 | 3747 | 3745 | 1179 | 2 | 1315 | 1183 | 0 |
| 8 | 10 | 1 | 4846 | 4843 | 2276 | 3 | 255 | 275 | 0 |
| 8 | 10 | 42 | 4820 | 4817 | 2258 | 3 | 275 | 151 | 0 |
| 32 | 16 | 1 | 4964 | 4961 | 2370 | 3 | 161 | 187 | 0 |
| 32 | 16 | 42 | 4912 | 4909 | 2339 | 3 | 207 | 89 | 0 |
| 128 | 256 | 1 | 6083 | 6080 | 2522 | 3 | 2 | 268 | 0 |
| 128 | 256 | 42 | 6077 | 6074 | 2483 | 3 | 2 | 124 | 0 |

Writes/reads include simultaneous accepted operations. In every regression, writes = reads + reset-discarded. These deterministic seeds apply to the new xorshift stimulus, not the original simulator random generator. Depth 1 correctly has zero simultaneous accepted operations under the existing boundary semantics.

Original scoreboard: width 8, depth 10; write-only 2502, read-only 2499, simultaneous 2249, blocked writes 255, blocked reads 234, final queue 3. It did not drain at completion. Original concurrent assertions/cover properties were unsupported by Starter, so there is no assertion/coverage pass or closure claim. The added procedural regression directly checks occupancy, flags, data, reset, and draining.

No RTL fixes were applied. This is simulation evidence only; no synthesis, hardware, or exhaustive verification is claimed. Raw logs are preserved beside this report.
