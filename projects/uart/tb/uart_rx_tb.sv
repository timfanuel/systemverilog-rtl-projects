`timescale 1ns/1ps

module uart_rx_tb;
    localparam int CLKS_PER_BIT = 8;

    logic clk;
    logic rst;
    logic [7:0] rx_data;
    logic rx_valid;
    logic rx_serial;
    logic rx_sync2_q;

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state_q;

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_serial(rx_serial)
    );

    logic saw_rx_valid;

    always @(posedge rx_valid) begin
        saw_rx_valid = 1'b1;
    end

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task automatic drive_uart_byte(input logic [7:0] data);
        begin

            // START
            @(negedge clk);
            rx_serial = 1'b0;
            repeat (CLKS_PER_BIT) @(negedge clk);

            // DATA D0-D7
            for (int i = 0; i < 8; i++) begin
                rx_serial = data[i];
                repeat (CLKS_PER_BIT) @(negedge clk);
            end

            // STOP
            // drive 1
            // hold for CLKS_PER_BIT clocks
            rx_serial = 1'b1;
            repeat (CLKS_PER_BIT) @(negedge clk);

        end
    endtask

    task automatic drive_false_start;
        begin
            @(negedge clk);
            rx_serial = 1'b0;

            // Brief low pulse, shorter than half a UART bit
            repeat (2) @(negedge clk);

            rx_serial = 1'b1;
        end
    endtask

    initial begin
        rst      = 1'b1;
        rx_serial = 1'b1;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = '0;

        saw_rx_valid = 1'b0;

        // Generate false start
        drive_false_start();

        // Give receiver enough time to reject it
        repeat (CLKS_PER_BIT) @(posedge clk);

        if (saw_rx_valid)
            $error("FAIL: rx_valid asserted during false start");
        else
            $display("PASS: False start correctly rejected");

        saw_rx_valid = 1'b0;

        fork
            begin
                drive_uart_byte(8'hA5);
            end

            begin
                @(posedge rx_valid);

                if (rx_data !== 8'hA5)
                    $error("Expected A5, got %h", rx_data);
                else
                    $display("PASS: Receiver recovered and received %h", rx_data);
            end
        join

        $finish; 

    end

endmodule