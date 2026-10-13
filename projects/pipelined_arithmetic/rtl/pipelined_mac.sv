module pipelined_mac #(
    parameter int WIDTH = 8
)(
    input  logic                 clk,
    input  logic                 rst,

    input  logic [WIDTH-1:0]     a,
    input  logic [WIDTH-1:0]     b,
    input  logic [WIDTH-1:0]     c,
    input  logic                 in_valid,
    output logic                 in_ready,

    output logic                 out_valid,
    input  logic                 out_ready,
    output logic [2*WIDTH:0]     out_data
);

    logic [WIDTH:0]   sum_q;
    logic [WIDTH-1:0] c_q;
    logic             valid1_q;

    logic [2*WIDTH:0] result_q;
    logic             valid2_q;

    logic stage_1_ready;
    logic stage_2_ready;

    assign stage_2_ready = !valid2_q || out_ready;
    assign stage_1_ready = !valid1_q || stage_2_ready;

    assign in_ready = stage_1_ready;
    assign out_valid = valid2_q;
    assign out_data = result_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            valid1_q <= 1'b0;
            valid2_q <= 1'b0;
        end
        else begin
            if (stage_1_ready) begin
                if (in_valid) begin
                    sum_q <= {1'b0, a} + {1'b0, b};
                    c_q <= c;
                    valid1_q <= 1'b1;
                end
                else begin
                    valid1_q <= 1'b0;
                end
            end

            if (stage_2_ready) begin
                if (valid1_q) begin
                    result_q <= sum_q * c_q;
                    valid2_q <= 1'b1;
                end
                else begin
                    valid2_q <= 1'b0;
                end
            end
        end
    end

endmodule
