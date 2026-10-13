# Historical synthesis reports

These files were copied without modification from an existing local Quartus project; synthesis was not rerun.

| Item | Saved evidence |
| --- | --- |
| Tool/date | Quartus Prime 25.1std.0, September 8, 2026 |
| Top/parameter | rv_pipeline, DATA_WIDTH=8 |
| Target | Cyclone V, 5CGXFC7C7F23C8 |
| Resources | 7 ALMs, 18 registers, 0 block memory bits, 0 DSP blocks |
| Timing limitations | Missing GPT1.sdc; 11 unconstrained input ports and 10 unconstrained output ports; timing requirements not met |
| Example warning | Worst-case setup slack -1.317 ns in the saved timing analysis |

`GPT1.map.rpt` records successful analysis and synthesis. `GPT1.flow.rpt` summarizes the historical compilation and utilization. `GPT1.sta.rpt` contains the timing warnings and unconstrained-path details. Tool completion does not establish timing closure. The reports retain Altera's original notices.

No source fingerprint accompanied the original project, so exact correspondence to the current RTL cannot be proven. No board or hardware validation is claimed. The original settings, pin assumptions, and missing timing constraints are not packaged as a reproducible hardware implementation.
