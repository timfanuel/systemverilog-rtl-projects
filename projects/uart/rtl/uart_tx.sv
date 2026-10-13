module uart_tx #(
    parameter int CLKS_PER_BIT = 4
)(
    input logic clk,
    input logic rst,

    input logic [7:0] tx_data,
    input logic tx_valid,
    output logic tx_ready,

    output logic tx_serial
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state_q;

    logic[7:0] data_q;
    logic[2:0] bit_index_q;

    logic [$clog2(CLKS_PER_BIT) - 1:0] baud_counter_q;

    always_ff @(posedge clk) begin
        if (rst) begin
            state_q <= IDLE;
            baud_counter_q <= '0;
            data_q <= '0;
            bit_index_q <= '0;
            tx_serial <= 1'b1;
            tx_ready  <= 1'b1;
        end
        else if (state_q == IDLE) begin
            tx_serial <= 1'b1;
            tx_ready <= 1'b1;
            if (tx_valid) begin
                data_q <= tx_data;
                baud_counter_q <= '0;
                tx_ready <= '0;
                state_q <= START;
            end
        end
        else if (state_q == START) begin
            tx_serial <= 1'b0;
            if (baud_counter_q == CLKS_PER_BIT - 1) begin
                baud_counter_q <= '0;
                state_q <= DATA;
            end
            else baud_counter_q <= baud_counter_q + 1;
        end
        else if (state_q == DATA) begin
            tx_serial <= data_q[bit_index_q];
            if (baud_counter_q == CLKS_PER_BIT - 1) begin
                if (bit_index_q != 3'b111) begin
                    bit_index_q <= bit_index_q + 1;
                    baud_counter_q <= '0;
                end
                else begin
                    state_q <= STOP;
                    baud_counter_q <= '0;
                end
            end
            else begin
                baud_counter_q <= baud_counter_q + 1;
            end
        end
        else if (state_q == STOP) begin
            tx_serial <= 1'b1;
            if (baud_counter_q == CLKS_PER_BIT - 1) begin
                baud_counter_q <= '0;
                bit_index_q <= '0;
                tx_ready <= 1'b1;
                state_q <= IDLE;
            end
            else begin
                baud_counter_q <= baud_counter_q + 1;
            end
        end
    end
endmodule


