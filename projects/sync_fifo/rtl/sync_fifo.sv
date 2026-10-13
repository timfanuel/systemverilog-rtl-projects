module sync_fifo #(
    parameter DATA_WIDTH = 128,
    parameter DEPTH      = 256
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,

    output logic                  full,
    output logic                  empty
);

    localparam PTR_WIDTH =
        (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    localparam COUNT_WIDTH =
        $clog2(DEPTH + 1);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0]   write_ptr;
    logic [PTR_WIDTH-1:0]   read_ptr;
    logic [COUNT_WIDTH-1:0] count;

    logic do_write;
    logic do_read;

    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    assign do_write = wr_en && !full;
    assign do_read  = rd_en && !empty;

    // Write logic
    always_ff @(posedge clk) begin
        if (rst) begin
            write_ptr <= '0;
        end
        else if (do_write) begin
            mem[write_ptr] <= wr_data;

            if (write_ptr == DEPTH - 1)
                write_ptr <= '0;
            else
                write_ptr <= write_ptr + 1'b1;
        end
    end

    // Read logic
    always_ff @(posedge clk) begin
        if (rst) begin
            read_ptr <= '0;
            rd_data  <= '0;
        end
        else if (do_read) begin
            rd_data <= mem[read_ptr];

            if (read_ptr == DEPTH - 1)
                read_ptr <= '0;
            else
                read_ptr <= read_ptr + 1'b1;
        end
    end

    // FIFO occupancy count
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= '0;
        end
        else begin
            case ({do_write, do_read})
                2'b10:   count <= count + 1'b1;
                2'b01:   count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule