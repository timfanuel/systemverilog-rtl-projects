
module rv_pipeline #(
    parameter DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  in_valid,
    output logic                  in_ready,
    input  logic [DATA_WIDTH-1:0] in_data,

    output logic                  out_valid,
    input  logic                  out_ready,
    output logic [DATA_WIDTH-1:0] out_data
);

    logic                  s1_valid;
    logic [DATA_WIDTH-1:0] s1_data;
    logic                  s1_ready;

    logic                  s2_valid;
    logic [DATA_WIDTH-1:0] s2_data;
    logic                  s2_ready;

    // Ready propagates backward
    assign s2_ready = !s2_valid || out_ready;
    assign s1_ready = !s1_valid || s2_ready;

    assign in_ready = s1_ready;

    // Output is whatever is currently stored in stage 2
    assign out_valid = s2_valid;
    assign out_data  = s2_data;

    // Stage 1
    always_ff @(posedge clk) begin
        if (rst) begin
            s1_valid <= 1'b0;
            s1_data  <= '0;
        end
        else if (s1_ready) begin
            s1_valid <= in_valid;

            if (in_valid)
                s1_data <= in_data;
        end
    end

    // Stage 2
    always_ff @(posedge clk) begin
        if (rst) begin
            s2_valid <= 1'b0;
            s2_data  <= '0;
        end
        else if (s2_ready) begin
            s2_valid <= s1_valid;

            if (s1_valid)
                s2_data <= s1_data;
        end
    end

endmodule