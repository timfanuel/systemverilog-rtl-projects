module rv_pipeline_tb;

    localparam DATA_WIDTH = 8;

    logic clk;
    logic rst;

    logic                  in_valid;
    logic                  in_ready;
    logic [DATA_WIDTH-1:0] in_data;

    logic                  out_valid;
    logic                  out_ready;
    logic [DATA_WIDTH-1:0] out_data;

    logic input_transfer;
    logic output_transfer;

    logic [DATA_WIDTH-1:0] expected_queue[$];
    logic [DATA_WIDTH-1:0] expected;

    int input_count;
    int output_count;
    int stall_count;

    rv_pipeline #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),

        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_data(in_data),

        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data)
    );

    initial clk = 1'b0;
    always #5ns clk = ~clk;

    assign input_transfer  = in_valid  && in_ready;
    assign output_transfer = out_valid && out_ready;

    initial begin
        rst       = 1'b1;
        in_valid  = 1'b0;
        in_data   = '0;
        out_ready = 1'b0;

        repeat (2) @(posedge clk);
        rst = 1'b0;
    end

    // If output is stalled, valid/data must remain stable.
    assert property (@(posedge clk)
        disable iff (rst)
        (out_valid && !out_ready)
        |=> (out_valid && $stable(out_data))
    );

    initial begin
        input_count  = 0;
        output_count = 0;
        stall_count  = 0;

        wait (!rst);

        repeat (10000) begin

            @(negedge clk);

            in_valid  = $urandom_range(0, 1);
            out_ready = $urandom_range(0, 1);
            in_data   = $urandom;

            if (out_valid && !out_ready)
                stall_count++;

            @(posedge clk);

            if (input_transfer) begin
                expected_queue.push_back(in_data);
                input_count++;
            end

            if (output_transfer) begin

                if (expected_queue.size() == 0) begin
                    $error("Output transfer occurred with empty scoreboard");
                end
                else begin
                    expected = expected_queue.pop_front();

                    if (out_data !== expected)
                        $error(
                            "Pipeline mismatch: expected %0h, got %0h",
                            expected,
                            out_data
                        );
                end

                output_count++;
            end
        end

        // Stop inserting new inputs.
        @(negedge clk);
        in_valid = 1'b0;

        // Let remaining pipeline contents drain.
        out_ready = 1'b1;

        while (expected_queue.size() != 0) begin
            @(posedge clk);

            if (output_transfer) begin
                expected = expected_queue.pop_front();

                if (out_data !== expected)
                    $error(
                        "Drain mismatch: expected %0h, got %0h",
                        expected,
                        out_data
                    );

                output_count++;
            end
        end

        @(negedge clk);

        $display("");
        $display("----- READY/VALID PIPELINE SUMMARY -----");
        $display("Input transfers:       %0d", input_count);
        $display("Output transfers:      %0d", output_count);
        $display("Output stall cycles:   %0d", stall_count);
        $display("Final queue size:      %0d", expected_queue.size());
        $display("----------------------------------------");
        $display("");

        if (input_count != output_count)
            $error("Transfer count mismatch");

        $finish;
    end

endmodule
