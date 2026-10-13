# Publication audit

Completed October 12, 2026. Scope: selected repository files, excluding ignored simulator build products and Git metadata.

- No credential-pattern hits or sensitive credential filenames found. Checks covered private key headers, GitHub token formats, AWS access key IDs, common API tokens, and quoted credential assignments; values were not printed. This is a bounded inspection, not a guarantee.
- No selected file exceeds 1 MiB. Largest selected file: `reports/synthesis/GPT1.sta.rpt` (81456 bytes). Raw VCD, simulation databases, programming binaries, and unrelated generated files are excluded from staging.
- Original RTL and original testbench are byte-for-byte unchanged. Saved Quartus reports retain their original notices.
- No third-party source notice was discovered in the selected RTL/testbench. New verification and documentation were prepared for this portfolio.
- The owner says the pipeline should be independent work; nearby coursework is excluded. No applicable sharing policy was available to independently verify that statement.
- At the time of this prepublication audit, no public upload or push had been performed. The owner subsequently created the public repository and approved uploading the prepared package.

## SHA-256 of preserved source files

| File | SHA-256 |
| --- | --- |
| rtl/rv_pipeline.sv | 82a049f0a8ffa6a4ac0b371520643112be8350364b7aef17f67047bd47e50359 |
| tb/rv_pipeline_tb.sv | df7e2fc15732dadefe2d6d8e1d20cc471e03e29f17c3ea947c4921560377832b |
