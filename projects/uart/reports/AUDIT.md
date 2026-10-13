# UART publication audit

Reviewed October 13, 2026. The owner explicitly approved publication of this selected TX/RX core package. Excluded UART wrappers and local diagnostic evidence are not part of that approval.

- Original three RTL modules and four existing testbenches match local source bytes exactly. Two focused regression testbenches and simulation/rendering scripts are newly added.
- No checked credential pattern or source attribution notice was found. Pattern scanning is bounded and cannot guarantee the absence of secrets or prove authorship.
- No applicable course restriction was discovered in selected sources; no policy document was available to verify sharing rights independently.
- No selected file exceeds 1 MiB. Generated VCDs, libraries, and databases are excluded.
- Excluded: echo wrapper with measured loss under sustained traffic; command demo with unverified heavy-query behavior; incompatible older TX; incomplete register stub.
- No synthesis or hardware implementation evidence is claimed.

| Preserved file | SHA-256 |
| --- | --- |
| rtl/uart_tx.sv | 6da718e3cc54fee13e46685c160ad5c4909f43242a81db0879667019fc5a0ab4 |
| rtl/uart_rx.sv | d1a06a9d2d8218b92ac2b6a3f434d99d7cc92974ad2c864c3acb901a5d46e4ad |
| rtl/uart.sv | d1e1bdd5bb7be917c85d998ca3b0928312a7e07cb570a8dcc7d2b5874b6de549 |
| tb/uart_tx_tb.sv | aeb2f700765f6a7f31276eb7ee050405e39ed01da8902445b4d4ec6eb9656121 |
| tb/uart_tx_tb2.sv | 20faedd1954d275fd759bbd9a3eee95a69709689a2a7af37688558e00b81a996 |
| tb/uart_rx_tb.sv | d8bc8c57a357fe0a1717bea61039e095ee312c40c267da42d7d94b1da0f6ad42 |
| tb/uart_loopback_tb.sv | fc1c98c3f2d4e351c0bb9b8609abc60ab7a5e82aed31120b7612a2c2676528e3 |
