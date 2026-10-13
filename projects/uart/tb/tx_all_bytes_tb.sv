`timescale 1ns/1ps
module tx_all_bytes_tb;
    localparam N=8;
    logic clk=0, rst=1, tx_valid=0, tx_ready, tx_serial;
    logic [7:0] tx_data=0;
    always #5 clk=~clk;
    uart_tx #(.CLKS_PER_BIT(N)) dut (.*);
    integer checked=0;
    task automatic send(input logic [7:0] b);
        @(negedge clk);
        while(tx_ready!==1) @(negedge clk);
        tx_data=b; tx_valid=1;
        @(negedge clk);
        if(tx_ready!==0) $fatal(1,"Ready did not fall after acceptance");
        tx_valid=0; tx_data=~b;
        repeat(3) @(negedge clk);
        // Busy-time valid pulse must not replace the latched frame.
        tx_valid=1;
        @(negedge clk); tx_valid=0;
    endtask
    task automatic check(input logic [7:0] b);
        @(negedge tx_serial);
        repeat(N/2) @(negedge clk);
        if(tx_serial!==0) $fatal(1,"Start bit");
        for(integer j=0;j<8;j++) begin
            repeat(N) @(negedge clk);
            if(tx_serial!==b[j]) $fatal(1,"Payload bit %0d for byte %h",j,b);
            if(tx_ready!==0) $fatal(1,"Ready asserted during data");
        end
        repeat(N) @(negedge clk);
        if(tx_serial!==1) $fatal(1,"Stop bit");
        checked++;
    endtask
    initial begin
        repeat(2) @(negedge clk); rst=0;
        if(tx_serial!==1 || tx_ready!==1) $fatal(1,"Idle/reset outputs");
        for(integer i=0;i<256;i++) begin
            fork
                send(i);
                check(i);
            join
        end
        while(tx_ready!==1) @(negedge clk);
        repeat(12*N) @(negedge clk);
        if(tx_serial!==1 || tx_ready!==1 || checked!=256) $fatal(1,"Final idle/accounting");
        $display("PASS TX_ALL_BYTES frames=%0d: 8N1 payloads, input latching, busy-time valid rejection",checked);
        $finish;
    end
    initial begin #300000; $fatal(1,"Timeout"); end
endmodule
