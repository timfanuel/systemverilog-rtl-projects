`timescale 1ns/1ps

module uart_tx_tb_extended;

    localparam int CLKS_PER_BIT = 4;

    logic clk;
    logic rst;
    logic [7:0] tx_data;
    logic tx_valid;
    logic tx_ready;
    logic tx_serial;

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

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    task automatic check_uart_byte(input logic [7:0] expected);
        integer i;

        begin
            // Wait for the falling edge that starts the START bit
            @(negedge tx_serial);

            // Move approximately to the middle of the START bit
            repeat (CLKS_PER_BIT/2) @(posedge clk);

            if (tx_serial != 0) $error("Expected 0, got 1");

            // verify D0 through D7
            for (int i = 0; i < 8; i++) begin
                repeat (CLKS_PER_BIT) @(posedge clk);

                if (tx_serial !== expected[i])
                    $error(
                        "Bit %0d: expected %0d, got %0d",
                        i,
                        expected[i],
                        tx_serial
                    );
            end

            // Move from middle of D7 to middle of STOP bit
            repeat (CLKS_PER_BIT) @(posedge clk);

            // verify STOP bit is 1
            if (tx_serial !== 1'b1)
                $error("Expected STOP bit 1, got %0d", tx_serial);
        end
    endtask

    initial begin
        rst      = 1;
        tx_data  = 0;
        tx_valid = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 0;

        

        tx_data = 8'hA5;
        tx_valid = 1;

        while (!tx_ready)
            @(posedge clk);

        @(posedge clk);
        @(negedge clk);
        tx_valid = 0;
        fork

            // Thread 1: verify the byte actually transmitted is still A5
            begin
                check_uart_byte(8'hA5);
            end

            // Thread 2: change external inputs while UART is busy
            begin
                repeat (5) @(posedge clk);

                tx_data = 8'h3C;

                // pulse tx_valid while transmitter is busy
                tx_valid = 1'b1;
                @(posedge clk);
                @(negedge clk);
                tx_valid = 1'b0;
            end

        join

        $stop;
    end

endmodule
