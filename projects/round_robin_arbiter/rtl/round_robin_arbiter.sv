module round_robin_arbiter (
    input  logic       clk,
    input  logic       rst,
    input  logic [3:0] req,
    output logic [3:0] grant
);

    logic [1:0] last_grant;

    // Remember who was most recently granted
    always_ff @(posedge clk) begin
        if (rst)
            last_grant <= 2'd3;
        else if (grant[0])
            last_grant <= 2'd0;
        else if (grant[1])
            last_grant <= 2'd1;
        else if (grant[2])
            last_grant <= 2'd2;
        else if (grant[3])
            last_grant <= 2'd3;
    end

    // Rotating-priority combinational logic
    always_comb begin
        grant = 4'b0000;

        case (last_grant)

            2'd0: begin
                if (req[1])
                    grant[1] = 1'b1;
                else if (req[2])
                    grant[2] = 1'b1;
                else if (req[3])
                    grant[3] = 1'b1;
                else if (req[0])
                    grant[0] = 1'b1;
            end

            2'd1: begin
                if (req[2])
                    grant[2] = 1'b1;
                else if (req[3])
                    grant[3] = 1'b1;
                else if (req[0])
                    grant[0] = 1'b1;
                else if (req[1])
                    grant[1] = 1'b1;
            end

            2'd2: begin
                if (req[3])
                    grant[3] = 1'b1;
                else if (req[0])
                    grant[0] = 1'b1;
                else if (req[1])
                    grant[1] = 1'b1;
                else if (req[2])
                    grant[2] = 1'b1;
            end

            2'd3: begin
                if (req[0])
                    grant[0] = 1'b1;
                else if (req[1])
                    grant[1] = 1'b1;
                else if (req[2])
                    grant[2] = 1'b1;
                else if (req[3])
                    grant[3] = 1'b1;
            end

        endcase
    end

endmodule