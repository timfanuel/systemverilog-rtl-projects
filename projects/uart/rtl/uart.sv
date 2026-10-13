module uart #(
    parameter int CLKS_PER_BIT = 434
)(
    input  logic       clk,
    input  logic       rst,

    // Parallel transmit interface
    input  logic [7:0] tx_data,
    input  logic       tx_valid,
    output logic       tx_ready,

    // Parallel receive interface
    output logic [7:0] rx_data,
    output logic       rx_valid,

    // Physical UART pins
    output logic       uart_tx,
    input  logic       uart_rx
);

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_inst (
        .clk       (clk),
        .rst       (rst),
        .tx_data   (tx_data),
        .tx_valid  (tx_valid),
        .tx_ready  (tx_ready),
        .tx_serial (uart_tx)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_inst (
        .clk    (clk),
        .rst    (rst),
        .rx_data    (rx_data),
        .rx_valid   (rx_valid),
        .rx_serial  (uart_rx)
    );


endmodule
