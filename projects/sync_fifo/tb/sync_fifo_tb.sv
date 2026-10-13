module sync_fifo_tb;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 10;

    logic clk;
    logic rst;

    logic                  wr_en;
    logic [DATA_WIDTH-1:0] wr_data;

    logic                  rd_en;
    logic [DATA_WIDTH-1:0] rd_data;

    logic full;
    logic empty;

    logic accepted_write;
    logic accepted_read;

    logic [DATA_WIDTH-1:0] expected_queue[$];

    int write_count;
    int read_count;
    int simultaneous_count;
    int blocked_write_count;
    int blocked_read_count;

    int op;

    logic [DATA_WIDTH-1:0] random_data;
    logic [DATA_WIDTH-1:0] expected;

    logic read_happened;
    logic write_happened;


    // -------------------------
    // DUT
    // -------------------------

    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_data(rd_data),

        .full(full),
        .empty(empty)
    );


    // -------------------------
    // Clock
    // -------------------------

    initial clk = 1'b0;

    always #5ns clk = ~clk;


    // -------------------------
    // Accepted operations
    // -------------------------

    assign accepted_write = wr_en && !full;
    assign accepted_read  = rd_en && !empty;


    // -------------------------
    // Reset
    // -------------------------

    initial begin
        rst     = 1'b1;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = '0;

        repeat (2)
            @(posedge clk);

        rst = 1'b0;
    end


    // -------------------------
    // Assertions
    // -------------------------

    assert property (@(posedge clk)
        disable iff (rst)
        dut.count <= DEPTH
    );

    assert property (@(posedge clk)
        disable iff (rst)
        empty |-> dut.count == 0
    );

    assert property (@(posedge clk)
        disable iff (rst)
        full |-> dut.count == DEPTH
    );

    assert property (@(posedge clk)
        disable iff (rst)
        (accepted_write && !accepted_read)
        |=> dut.count == $past(dut.count) + 1
    );

    assert property (@(posedge clk)
        disable iff (rst)
        (accepted_read && !accepted_write)
        |=> dut.count == $past(dut.count) - 1
    );

    assert property (@(posedge clk)
        disable iff (rst)
        (accepted_write && accepted_read)
        |=> dut.count == $past(dut.count)
    );

    assert property (@(posedge clk)
        disable iff (rst)
        !$isunknown(dut.count)
    );


    // -------------------------
    // Coverage
    // -------------------------

    cover property (@(posedge clk)
        disable iff (rst)
        full && wr_en
    );

    cover property (@(posedge clk)
        disable iff (rst)
        empty && rd_en
    );

    cover property (@(posedge clk)
        disable iff (rst)
        accepted_write && accepted_read
    );

    cover property (@(posedge clk)
        disable iff (rst)
        $rose(full)
    );

    cover property (@(posedge clk)
        disable iff (rst)
        $rose(empty)
    );


    // -------------------------
    // Randomized test
    // -------------------------

    initial begin

        write_count         = 0;
        read_count          = 0;
        simultaneous_count = 0;
        blocked_write_count = 0;
        blocked_read_count  = 0;

        wait (!rst);

        //
        // Run randomized traffic
        //
        repeat (10000) begin

            op          = $urandom_range(0, 3);
            random_data = $urandom;

            @(negedge clk);

            case (op)

                // Idle
                0: begin
                    wr_en = 1'b0;
                    rd_en = 1'b0;
                end

                // Write
                1: begin
                    wr_en   = 1'b1;
                    rd_en   = 1'b0;
                    wr_data = random_data;
                end

                // Read
                2: begin
                    wr_en = 1'b0;
                    rd_en = 1'b1;
                end

                // Simultaneous read/write
                3: begin
                    wr_en   = 1'b1;
                    rd_en   = 1'b1;
                    wr_data = random_data;
                end

            endcase


            //
            // Remember boundary attempts
            //
            if (wr_en && full)
                blocked_write_count++;

            if (rd_en && empty)
                blocked_read_count++;


            //
            // DUT samples inputs here
            //
            @(posedge clk);

            write_happened = accepted_write;
            read_happened  = accepted_read;


            //
            // Update scoreboard
            //
            if (write_happened)
                expected_queue.push_back(wr_data);

            if (read_happened) begin

                if (expected_queue.size() == 0) begin
                    $error("Scoreboard unexpectedly empty");
                end
                else begin
                    expected = expected_queue.pop_front();
                end

            end


            //
            // Count accepted operation types
            //
            if (write_happened && read_happened)
                simultaneous_count++;
            else if (write_happened)
                write_count++;
            else if (read_happened)
                read_count++;


            //
            // Wait for rd_data NBA update
            //
            @(negedge clk);

            if (read_happened) begin
                if (rd_data !== expected) begin
                    $error(
                        "FIFO mismatch: expected %0h, got %0h",
                        expected,
                        rd_data
                    );
                end
            end


            //
            // Remove requests
            //
            wr_en = 1'b0;
            rd_en = 1'b0;

        end


        // -------------------------
        // Results
        // -------------------------

        $display("");
        $display("----- FIFO RANDOM TEST SUMMARY -----");
        $display("Write-only accepted:   %0d", write_count);
        $display("Read-only accepted:    %0d", read_count);
        $display("Simultaneous R/W:      %0d", simultaneous_count);
        $display("Blocked writes (full): %0d", blocked_write_count);
        $display("Blocked reads (empty): %0d", blocked_read_count);
        $display("Final scoreboard size: %0d", expected_queue.size());
        $display("------------------------------------");
        $display("");

        $finish;

    end

endmodule