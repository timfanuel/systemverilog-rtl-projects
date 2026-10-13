`timescale 1ns/1ps

module pipelined_mac_tb;

    parameter int WIDTH = 8;

    logic clk;
    logic rst;

    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic [WIDTH-1:0] c;

    logic in_valid;
    logic in_ready;

    logic out_valid;
    logic out_ready;
    logic [2*WIDTH:0] out_data;

    int expected [0:2];
    int result_index;

    

    pipelined_mac #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),

        .a(a),
        .b(b),
        .c(c),

        .in_valid(in_valid),
        .in_ready(in_ready),

        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin

        // Initial values
        rst       = 1;
        a         = 0;
        b         = 0;
        c         = 0;
        in_valid  = 0;
        out_ready = 1;

        expected[0] = 20;
        expected[1] = 60;
        expected[2] = 27;

        result_index = 0;

        // Reset sequence
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 0;

                // Transaction 1: (2 + 3) * 4 = 20
        a = 2;
        b = 3;
        c = 4;
        in_valid = 1;
        out_ready = 1;

        @(negedge clk);

        // Transaction 2: (5 + 1) * 10 = 60
        a = 5;
        b = 1;
        c = 10;

        @(negedge clk);

        // Stall the consumer
        out_ready = 0;

        // Transaction 3: (7 + 2) * 3 = 27
        a = 7;
        b = 2;
        c = 3;

        // Hold this transaction while the pipeline is blocked
        repeat (3) @(negedge clk);

        // Consumer becomes ready again
        out_ready = 1;

        @(negedge clk);

        // Transaction 3 should now have been accepted
        in_valid = 0;

        repeat (5) @(posedge clk);

        $stop;


    end

    always @(posedge clk) begin
        if (!rst && out_valid && out_ready) begin

            if (out_data !== expected[result_index]) begin
                $error(
                    "Mismatch! Expected %0d, got %0d",
                    expected[result_index],
                    out_data
                );
            end
            else begin
                $display(
                    "PASS: Expected %0d, got %0d",
                    expected[result_index],
                    out_data
                );
            end

            result_index = result_index + 1;
        end
    end

endmodule