`timescale 1ns/1ps
// Portable checks: no concurrent assertions or simulator randomization support required.
module rv_pipeline_regression_tb;
    parameter integer DATA_WIDTH = 8;
    parameter integer SEED = 1;
    logic clk = 0;
    always #5 clk = ~clk;
    logic rst = 1, in_valid = 0, out_ready = 0;
    logic in_ready, out_valid;
    logic [DATA_WIDTH-1:0] in_data = 0, out_data;
    logic [DATA_WIDTH-1:0] queue[$], expected, held_data;
    bit held_output = 0, held_input = 0;
    integer accepted = 0, delivered = 0, stalls = 0, flushed = 0;
    integer consecutive = 0, max_consecutive = 0;
    logic [31:0] prng = SEED;

    rv_pipeline #(.DATA_WIDTH(DATA_WIDTH)) dut (.*);

    function automatic logic [31:0] next_random(input logic [31:0] value);
        // xorshift32, deterministic across simulators; SEED must be nonzero.
        logic [31:0] x;
        x = value ^ (value << 13);
        x = x ^ (x >> 17);
        return x ^ (x << 5);
    endfunction

    task automatic cycle(input bit reset_value, valid_value, ready_value,
                         input logic [DATA_WIDTH-1:0] data_value);
        @(negedge clk);
        rst = reset_value;
        in_valid = valid_value;
        out_ready = ready_value;
        in_data = data_value;
        @(posedge clk);
        if (rst) begin
            flushed += queue.size();
            queue.delete();
            held_output = 0;
            held_input = 0;
            consecutive = 0;
        end else begin
            if ($isunknown({in_ready, out_valid}))
                $fatal(1, "Unknown handshake signal");
            if (held_output && (out_valid !== 1'b1 || out_data !== held_data))
                $fatal(1, "Output changed while stalled");
            held_output = out_valid && !out_ready;
            held_data = out_data;
            held_input = in_valid && !in_ready;
            if (held_output) stalls++;
            // Read before write: the pipeline must not produce a zero-cycle bypass.
            if (out_valid && out_ready) begin
                if (queue.size() == 0) $fatal(1, "Unexpected output");
                expected = queue.pop_front();
                if (out_data !== expected) $fatal(1, "Data/order mismatch");
                delivered++;
                consecutive++;
                if (consecutive > max_consecutive) max_consecutive = consecutive;
            end else consecutive = 0;
            if (in_valid && in_ready) begin
                queue.push_back(in_data);
                accepted++;
            end
            if (queue.size() > 2) $fatal(1, "Capacity exceeded");
        end
        #1; // Inspect registered reset effects after nonblocking updates.
        if (rst && (out_valid !== 0 || out_data !== '0))
            $fatal(1, "Reset did not clear output");
    endtask

    initial begin
        if (DATA_WIDTH < 1 || DATA_WIDTH > 32 || SEED == 0)
            $fatal(1, "Regression supports widths 1..32 and nonzero seed");
        cycle(1, 0, 0, 0);
        cycle(0, 1, 0, 'h35);
        if (out_valid !== 0) $fatal(1, "Output appeared too early");
        cycle(0, 1, 0, 'hca);
        if (in_ready !== 0 || out_valid !== 1) $fatal(1, "Full pipeline flags");
        repeat (8) cycle(0, 0, 0, 0);
        cycle(0, 0, 1, 0);
        cycle(0, 0, 1, 0);
        if (queue.size() != 0 || out_valid !== 0) $fatal(1, "Drain failed");
        // Directed continuous traffic establishes one transfer per cycle after fill.
        for (integer i = 0; i < 32; i++) cycle(0, 1, 1, i);
        repeat (3) cycle(0, 0, 1, 0);
        if (max_consecutive < 32) $fatal(1, "Throughput check failed");
        // Reset while occupied explicitly discards both pending words.
        cycle(0, 1, 0, 'h12);
        cycle(0, 1, 0, 'h34);
        cycle(1, 0, 0, 0);
        if (flushed != 2) $fatal(1, "Reset flush setup failed");
        for (integer i = 0; i < 10000; i++) begin
            prng = next_random(prng);
            // A compliant producer retains valid/data until its transfer succeeds.
            if (held_input) cycle(0, 1, prng[1], in_data);
            else cycle(0, prng[0], prng[1], prng);
        end
        if (held_input) cycle(0, 1, 1, in_data);
        repeat (3) cycle(0, 0, 1, 0);
        if (queue.size() != 0 || out_valid !== 0 || accepted != delivered + flushed)
            $fatal(1, "Final accounting/drain failed");
        if (stalls < 8) $fatal(1, "Stall scenario missing");
        $display("PASS width=%0d seed=%0d accepted=%0d delivered=%0d flushed=%0d stalls=%0d max_consecutive=%0d",
                 DATA_WIDTH, SEED, accepted, delivered, flushed, stalls, max_consecutive);
        $finish;
    end
    initial begin
        #200000;
        $fatal(1, "Regression timeout");
    end
endmodule
