`timescale 1ns/1ps

module pipelined_mac_random_tb;

    parameter int WIDTH = 8;
    parameter int NUM_CYCLES = 100;

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

    // Queue holding expected results
    logic [2*WIDTH:0] expected_q[$];

    int inputs_accepted;
    int outputs_checked;
    int errors;

    logic accepted_previous_cycle;
    logic [2*WIDTH:0] expected_value;


    // -------------------------
    // DUT
    // -------------------------

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


    // -------------------------
    // Clock
    // -------------------------

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // -------------------------
    // Expected-result function
    // -------------------------

    function automatic logic [2*WIDTH:0] calculate_expected(
        input logic [WIDTH-1:0] aa,
        input logic [WIDTH-1:0] bb,
        input logic [WIDTH-1:0] cc
    );

        int unsigned a_int;
        int unsigned b_int;
        int unsigned c_int;

        begin
            a_int = aa;
            b_int = bb;
            c_int = cc;

            calculate_expected = (a_int + b_int) * c_int;
        end

    endfunction


    // -------------------------
    // Scoreboard
    // -------------------------

    always @(posedge clk) begin

        if (rst) begin
            expected_q.delete();

            inputs_accepted = 0;
            outputs_checked = 0;
            errors = 0;
        end

        else begin

            // Input transaction accepted
            if (in_valid && in_ready) begin

                expected_q.push_back(
                    calculate_expected(a, b, c)
                );

                inputs_accepted = inputs_accepted + 1;
            end


            // Output transaction accepted
            if (out_valid && out_ready) begin

                if (expected_q.size() == 0) begin
                    $error("DUT produced an output when queue was empty!");
                    errors = errors + 1;
                end

                else begin

                    expected_value = expected_q.pop_front();

                    if (out_data !== expected_value) begin

                        $error(
                            "Mismatch: expected %0d, got %0d",
                            expected_value,
                            out_data
                        );

                        errors = errors + 1;

                    end

                    outputs_checked = outputs_checked + 1;

                end
            end
        end
    end


    // -------------------------
    // Random stimulus
    // -------------------------

    initial begin

        rst       = 1;
        a         = 0;
        b         = 0;
        c         = 0;
        in_valid  = 0;
        out_ready = 1;

        accepted_previous_cycle = 0;


        // Reset
        repeat (2) @(posedge clk);

        @(negedge clk);
        rst = 0;


        // Run randomized traffic
        repeat (NUM_CYCLES) begin

            /*
             * First allow the current transaction to
             * reach a rising edge.
             */
            @(posedge clk);

            accepted_previous_cycle =
                in_valid && in_ready;


            /*
             * Change stimulus on falling edges so it is
             * stable before the next rising edge.
             */
            @(negedge clk);


            // Random output backpressure
            out_ready = $urandom_range(0, 1);


            /*
             * Generate a NEW input only when:
             *
             * 1. There wasn't already a valid transaction
             *
             * OR
             *
             * 2. The previous transaction was accepted.
             *
             * Otherwise we MUST hold a,b,c,in_valid stable.
             */
            if (!in_valid || accepted_previous_cycle) begin

                in_valid = $urandom_range(0, 1);

                if (in_valid) begin
                    a = $urandom_range(0, (1 << WIDTH) - 1);
                    b = $urandom_range(0, (1 << WIDTH) - 1);
                    c = $urandom_range(0, (1 << WIDTH) - 1);
                end

            end

        end


        // -------------------------
        // Stop generating traffic
        // and drain the pipeline
        // -------------------------

        out_ready = 1;


        // If one input is still waiting, let it be accepted
        if (in_valid) begin

            @(posedge clk);

            while (!in_ready)
                @(posedge clk);

            @(negedge clk);
            in_valid = 0;

        end


        // Plenty of time for our 2-stage pipeline to empty
        repeat (5) @(posedge clk);


        // -------------------------
        // Final report
        // -------------------------

        $display("");
        $display("----- TEST SUMMARY -----");
        $display("Inputs accepted : %0d", inputs_accepted);
        $display("Outputs checked : %0d", outputs_checked);
        $display("Errors          : %0d", errors);
        $display("Queue remaining : %0d", expected_q.size());

        if (
            errors == 0 &&
            expected_q.size() == 0 &&
            inputs_accepted == outputs_checked
        )
            $display("RANDOMIZED TEST PASSED");

        else
            $display("RANDOMIZED TEST FAILED");

        $stop;

    end

endmodule
