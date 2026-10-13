`timescale 1ns/1ps

module uart_loopback_tb;
    localparam int CLKS_PER_BIT = 8;

    logic clk;
    logic rst;

    // TX side
    logic [7:0] tx_data;
    logic       tx_valid;
    logic       tx_ready;
    logic       tx_serial;

    // RX side
    logic [7:0] rx_data;
    logic       rx_valid;

    logic [7:0] expected [0:4];


    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_dut (
        .clk(clk),
        .rst(rst),
        .tx_data(tx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .tx_serial(tx_serial)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_dut (
        .clk(clk),
        .rst(rst),
        .rx_serial(tx_serial),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    task automatic send_tx_byte(input logic [7:0] data);
        begin
            while (!tx_ready)
                @(posedge clk);

            @(negedge clk);
            tx_data  = data;
            tx_valid = 1'b1;

            @(posedge clk);

            @(negedge clk);
            tx_valid = 1'b0;
        end
        endtask

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        expected[0] = 8'hA5;
        expected[1] = 8'h3C;
        expected[2] = 8'h00;
        expected[3] = 8'hFF;
        expected[4] = 8'h55;
    end


    initial begin
        rst      = 1'b1;
        tx_data  = '0;
        tx_valid = 1'b0;

        repeat (2) @(posedge clk);

        @(negedge clk);
        rst = 1'b0;

        for (int i = 0; i < 5; i++) begin
            send_tx_byte(expected[i]);
            @(posedge rx_valid);
            if (rx_data !== expected[i]) $error("Expected %0h, got %0h", expected[i], rx_data);
        end

        $finish;
    end
endmodule
