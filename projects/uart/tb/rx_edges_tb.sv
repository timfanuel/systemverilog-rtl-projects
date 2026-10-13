`timescale 1ns/1ps
module rx_edges_tb;
    localparam N=8;
    logic clk=0, rst=1, rx_serial=1, rx_valid;
    logic [7:0] rx_data;
    always #5 clk=~clk;
    uart_rx #(.CLKS_PER_BIT(N)) dut (.*);
    integer count=0;
    bit previous_valid=0;
    always @(negedge clk) if (!rst) begin
        if (rx_valid && previous_valid) $fatal(1,"rx_valid wider than one cycle");
        previous_valid=rx_valid;
        if (rx_valid) count++;
    end
    task automatic frame(input logic [7:0] b, input bit good_stop);
        @(negedge clk); rx_serial=0;
        repeat (N) @(negedge clk);
        for(integer i=0;i<8;i++) begin
            rx_serial=b[i]; repeat(N) @(negedge clk);
        end
        rx_serial=good_stop;
        repeat(N) @(negedge clk);
        rx_serial=1;
        repeat(12*N) @(negedge clk);
    endtask
    initial begin
        repeat(2) @(negedge clk); rst=0;
        frame('h56,0);
        if(count!=0) $fatal(1,"Bad stop accepted");
        frame('h00,1);
        if(count!=1 || rx_data!=='h00) $fatal(1,"Recovery/zero failed");
        frame('hff,1);
        if(count!=2 || rx_data!=='hff) $fatal(1,"All-ones failed");
        @(negedge clk); rx_serial=0;
        repeat(3*N) @(negedge clk);
        rst=1;
        repeat(2) @(negedge clk);
        rx_serial=1; rst=0;
        repeat(12*N) @(negedge clk);
        if(count!=2) $fatal(1,"Reset did not discard partial frame");
        frame('ha5,1);
        if(count!=3 || rx_data!=='ha5) $fatal(1,"Reset recovery failed");
        $display("PASS RX_EDGES valid_frames=%0d: bad-stop rejection, reset abort/recovery, 00/FF/A5, one-cycle valid",count);
        $finish;
    end
    initial begin #100000; $fatal(1,"Timeout"); end
endmodule
