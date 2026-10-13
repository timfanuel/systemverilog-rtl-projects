`timescale 1ns/1ps

module uart_tx_tb;

    localparam int CLKS_PER_BIT = 4;

    logic clk;
    logic rst;

    logic [7:0] tx_data;
    logic       tx_valid;
    logic       tx_ready;
    logic       tx_serial;

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx_serial(tx_serial)
    );

    // 100 MHz-style simulation clock: 10 ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst      = 1;
        tx_data  = 8'h00;
        tx_valid = 0;

        // Hold reset for two clocks
        repeat (2) @(posedge clk);

        @(negedge clk);
        rst = 0;

        // Send 0xB4 = 1011_0100
        tx_data  = 8'hB4;
        tx_valid = 1;

        // Wait until transmitter accepts it
        @(posedge clk);

        @(negedge clk);
        tx_valid = 0;

        // Enough time for:
        // start + 8 data + stop = 10 UART bits
        // 10 * 4 clocks = 40 clocks
        repeat (45) @(posedge clk);

        $stop;
    end

endmodule
