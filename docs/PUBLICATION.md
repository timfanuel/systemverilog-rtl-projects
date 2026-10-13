# Scope and publication review

## Selected scope

This repository contains the ready/valid pipeline, its original testbench, an added regression, reproduction scripts, captured SVG waveforms, selected evidence, the separately approved pipelined arithmetic project under `projects/pipelined_arithmetic/`, and the separately approved UART TX/RX core under `projects/uart/`. The FIFO and arbiter were not located in the inspected FPGA and ModelSim folders; the owner agreed to defer them. The adapter `fifo_to_rv.sv` is not a FIFO implementation and has no discovered testbench, so it is excluded.

Original RTL/testbench files and saved synthesis reports were copied without modification. New files are documentation, verification, waveform rendering, and repository hygiene.

## Sharing and provenance

- Owner statement: the ready/valid pipeline **should be independent work**. Nearby ECE152 lab/homework files are excluded. No course restriction was found for the selected pipeline, but no syllabus or instructor policy was available to independently verify provenance.
- The selected RTL and original testbench contain no discovered third-party copyright, license, or attribution notice. Absence of a notice is not proof of authorship; retain attribution if an external source is later identified.
- Saved Quartus reports carry vendor legal notices, retained unchanged. Their inclusion does not assign a license to vendor material.
- No project-wide license was invented. The owner can choose a license for code they own; public visibility alone does not grant broad reuse rights.
- Only selected files are included; unrelated coursework, archives, credentials, vendor installations, tool databases, and programming artifacts are excluded.
- Credential and size inspection results and source hashes are recorded in [`AUDIT.md`](AUDIT.md). Automated pattern checks cannot guarantee that no secret exists.

## Publication authorization

The owner created `timfanuel/systemverilog-rtl-projects` as a public repository and explicitly approved uploading this pipeline-only package. The connected GitHub app authenticated as `timfanuel` and reported repository push permission. Publication does not extend the verification claims: simulation passed, the synthesis evidence is historical with timing warnings, and no physical hardware testing is claimed.

The owner subsequently gave separate approval to add the pipelined arithmetic project. Its RTL and two existing testbenches remain unchanged. Its directed test and 10,000-cycle randomized width-8 simulation passed; no arithmetic synthesis or hardware verification is claimed. No third-party source notice or applicable sharing policy was found in its selected files; original authorship was not independently established.

On October 13, 2026, the owner explicitly approved the selected UART TX/RX core package. It includes three unchanged RTL modules, four unchanged existing testbenches, two added focused tests, reproduction scripts, actual logs, and a captured waveform. The echo wrapper is excluded after a 256-frame stress test demonstrated three lost bytes; the command example, duplicate older transmitter, and unfinished register stub are also excluded. UART simulation limitations and source hashes are documented in `projects/uart/README.md` and `projects/uart/reports/AUDIT.md`. No UART synthesis or hardware claim is made.
