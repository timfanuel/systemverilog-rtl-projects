
module uart_rx #(
    parameter int CLKS_PER_BIT = 8
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       rx_serial,

    output logic [7:0] rx_data,
    output logic       rx_valid
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state_q;

    logic [7:0] data_q;
    logic [2:0] bit_index_q;

    logic [$clog2(CLKS_PER_BIT)-1:0] baud_counter_q;

    logic rx_sync1_q;
    logic rx_sync2_q;

    localparam int HALF_BIT = CLKS_PER_BIT / 2;

    always_ff @(posedge clk) begin
        if (rst) begin
            rx_sync1_q <= 1'b1;
            rx_sync2_q <= 1'b1;
        end
        else begin
            rx_sync1_q <= rx_serial;
            rx_sync2_q <= rx_sync1_q;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            data_q <= '0;
            bit_index_q <= '0;
            state_q <= IDLE;
            baud_counter_q <= '0;
            rx_valid <= '0;
            rx_data <= '0;
        end
        else begin
            rx_valid <= '0;
            
            case (state_q)
                IDLE : begin
                    if (!rx_sync2_q) begin
                        state_q <= START;
                        baud_counter_q <= '0;
                    end
                end

                START : begin
                    if (baud_counter_q == HALF_BIT - 1) begin
                        if (!rx_sync2_q) begin
                            baud_counter_q <= '0;
                            bit_index_q <= '0;
                            state_q <= DATA;
                        end
                        else begin
                            baud_counter_q <= '0;
                            state_q <= IDLE;
                        end
                    end
                    else begin
                        baud_counter_q <= baud_counter_q + 1;                        
                    end
                end

                DATA : begin
                    if (baud_counter_q == CLKS_PER_BIT - 1) begin

                        // Sample current data bit
                        data_q[bit_index_q] <= rx_sync2_q;
                        baud_counter_q <= '0;

                        if (bit_index_q == 3'd7) begin
                            // D7 was just sampled
                            bit_index_q <= '0;
                            state_q <= STOP;
                        end
                        else begin
                            // Move on to next data bit
                            bit_index_q <= bit_index_q + 1'b1;
                        end

                    end
                    else begin
                        baud_counter_q <= baud_counter_q + 1'b1;
                    end
                end

                STOP : begin
                    if (baud_counter_q == CLKS_PER_BIT - 1) begin
                        baud_counter_q <= '0;
                        if (rx_sync2_q) begin
                            rx_data <= data_q;
                            rx_valid <= 1'b1;
                        end

                        state_q <= IDLE;
                    end
                    else baud_counter_q <= baud_counter_q + 1;
                end

                default : begin
                    state_q <= IDLE;
                end
            endcase
        end
        
    end

endmodule