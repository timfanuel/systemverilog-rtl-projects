`timescale 1ns/1ps
module round_robin_arbiter_tb;
    parameter integer SEED=1;
    logic clk=0, rst=1;
    logic [3:0] req=0, grant;
    always #5 clk=~clk;
    round_robin_arbiter dut (.*);
    integer reference_last=3, checked=0, unique_pairs=0;
    integer coverage[0:3][0:15];
    integer age[0:3], served[0:3];
    logic [31:0] rng=SEED;

    function automatic logic [3:0] choose(input integer last, input logic [3:0] requests);
        integer index;
        choose=0;
        for(integer offset=1;offset<=4;offset++) begin
            index=(last+offset)%4;
            if(requests[index] && choose==0) choose[index]=1;
        end
    endfunction
    function automatic logic [31:0] next_random(input logic [31:0] value);
        logic [31:0] x;
        x=value^(value<<13); x=x^(x>>17); return x^(x<<5);
    endfunction
    task automatic check_grant(input logic [3:0] expected);
        if(grant !== expected) $fatal(1,"Priority mismatch: req=%b last=%0d expected=%b actual=%b",req,reference_last,expected,grant);
        if((grant & ~req)!==0 || !$onehot0(grant)) $fatal(1,"Invalid grant encoding/subset");
        if((req==0 && grant!=0) || (req!=0 && grant==0)) $fatal(1,"Missing/unexpected grant");
    endtask
    task automatic cycle(input bit reset_value,input logic [3:0] requests);
        logic [3:0] sampled;
        @(negedge clk); rst=reset_value; req=requests;
        #1;
        if(!rst) check_grant(choose(reference_last,req));
        sampled=grant;
        @(posedge clk);
        if(rst) begin
            reference_last=3;
            for(integer i=0;i<4;i++) begin age[i]=0; served[i]=0; end
        end else begin
            check_grant(choose(reference_last,req));
            if(coverage[reference_last][req]==0) unique_pairs++;
            coverage[reference_last][req]++;
            checked++;
            for(integer i=0;i<4;i++) begin
                if(!req[i] || sampled[i]) age[i]=0;
                else age[i]++;
                if(age[i]>3) $fatal(1,"Persistent requester waited more than three other service edges");
                if(sampled[i]) begin reference_last=i; served[i]++; end
            end
        end
        #1; // Rotation changes the combinational grant after the sampling edge.
        check_grant(choose(reference_last,req));
    endtask
    initial begin
        if(SEED==0) $fatal(1,"Seed must be nonzero");
        for(integer i=0;i<4;i++) begin
            age[i]=0; served[i]=0;
            for(integer j=0;j<16;j++) coverage[i][j]=0;
        end
        // Force each priority state through a real grant, then test every mask.
        for(integer last=0;last<4;last++) begin
            for(integer mask=0;mask<16;mask++) begin
                cycle(1,0);
                cycle(0,1<<last);
                cycle(0,mask);
            end
        end
        if(unique_pairs!=64) $fatal(1,"Missing priority/request combination");
        cycle(1,0);
        repeat(16) cycle(0,15);
        for(integer i=0;i<4;i++) if(served[i]!=4) $fatal(1,"Full-contention balance");
        // Every nonempty persistent subset must service each active requester.
        for(integer mask=1;mask<16;mask++) begin
            cycle(1,0);
            repeat(4) cycle(0,mask);
            for(integer i=0;i<4;i++) if(mask&(1<<i))
                if(served[i]==0) $fatal(1,"Persistent subset requester starved");
        end
        cycle(1,0); cycle(0,4); // Grant requester 2.
        repeat(5) cycle(0,0); // Idle must retain the last granted index.
        cycle(0,15);
        // Reset with requests asserted: grants are live, not reset-gated.
        cycle(1,15);
        if(grant!==1) $fatal(1,"Reset priority did not restart at requester 0");
        for(integer i=0;i<10000;i++) begin
            rng=next_random(rng); cycle(0,rng[3:0]);
        end
        $display("PASS ARBITER seed=%0d checked_cycles=%0d priority_request_pairs=%0d: onehot/subset, rotation, persistent fairness, idle retention, reset priority",
                 SEED,checked,unique_pairs);
        $finish;
    end
    initial begin #150000; $fatal(1,"Timeout"); end
endmodule
