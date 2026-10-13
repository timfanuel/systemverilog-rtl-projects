`timescale 1ns/1ps
module sync_fifo_regression_tb;
    parameter integer DATA_WIDTH=8, DEPTH=10, SEED=1;
    logic clk=0, rst=1, wr_en=0, rd_en=0, full, empty;
    logic [DATA_WIDTH-1:0] wr_data=0, rd_data;
    always #5 clk=~clk;
    sync_fifo #(.DATA_WIDTH(DATA_WIDTH),.DEPTH(DEPTH)) dut (.*);
    logic [DATA_WIDTH-1:0] queue[$], expected, held_data;
    logic [31:0] rng=SEED;
    integer writes=0, reads=0, simultaneous=0, blocked_w=0, blocked_r=0, flushed=0;
    function automatic logic [31:0] next_random(input logic [31:0] value);
        logic [31:0] x;
        x=value^(value<<13); x=x^(x>>17); return x^(x<<5);
    endfunction
    function automatic logic [DATA_WIDTH-1:0] payload(input logic [31:0] seed_value);
        logic [31:0] x;
        x=seed_value;
        for(integer b=0;b<DATA_WIDTH;b++) begin
            if(b%32==0) x=next_random(x);
            payload[b]=x[b%32];
        end
    endfunction
    task automatic cycle(input bit reset_value, write_value, read_value,
                         input logic [DATA_WIDTH-1:0] data_value);
        bit accepted_w, accepted_r;
        @(negedge clk);
        rst=reset_value; wr_en=write_value; rd_en=read_value; wr_data=data_value;
        @(posedge clk);
        accepted_w=0; accepted_r=0; held_data=rd_data;
        if(rst) begin
            flushed+=queue.size(); queue.delete();
        end else begin
            if(empty !== (queue.size()==0) || full !== (queue.size()==DEPTH))
                $fatal(1,"Flags disagree with reference occupancy before edge");
            accepted_w=wr_en&&!full; accepted_r=rd_en&&!empty;
            if(wr_en&&full) blocked_w++;
            if(rd_en&&empty) blocked_r++;
            // Read old head before appending a simultaneous write.
            if(accepted_r) begin
                if(queue.size()==0) $fatal(1,"Unexpected read");
                expected=queue.pop_front(); reads++;
            end
            if(accepted_w) begin queue.push_back(wr_data); writes++; end
            if(accepted_w&&accepted_r) simultaneous++;
        end
        #1;
        if(rst && rd_data !== '0) $fatal(1,"Read data not reset");
        if(!rst && accepted_r && rd_data !== expected) $fatal(1,"Read data/order mismatch");
        if(!rst && !accepted_r && rd_data !== held_data) $fatal(1,"Read output changed without accepted read");
        if(empty !== (queue.size()==0) || full !== (queue.size()==DEPTH) || dut.count !== queue.size())
            $fatal(1,"Flags/count disagree with reference occupancy after edge");
    endtask
    initial begin
        if(DATA_WIDTH<1 || DEPTH<1 || SEED==0) $fatal(1,"Invalid regression parameters");
        cycle(1,0,0,0);
        cycle(0,0,1,0); // Empty read blocked.
        cycle(0,1,1,'1); // Empty simultaneous request accepts write only.
        if(queue.size()!=1 || reads!=0) $fatal(1,"Empty-boundary semantics");
        cycle(0,0,1,0);
        for(integer i=0;i<DEPTH;i++) cycle(0,1,0,payload(i+1));
        cycle(0,1,0,0); // Full write blocked.
        cycle(0,1,1,0); // Full simultaneous request accepts read only.
        if(queue.size()!=DEPTH-1) $fatal(1,"Full-boundary semantics");
        if(DEPTH>1) cycle(0,1,1,'1); // Interior simultaneous read/write.
        repeat(DEPTH+1) cycle(0,0,1,0);
        // Multiple pointer wraps, including non-power-of-two depths.
        for(integer i=0;i<3*DEPTH;i++) begin
            cycle(0,1,0,payload(i+77));
            cycle(0,0,1,0);
        end
        for(integer i=0;i<DEPTH && i<3;i++) cycle(0,1,0,payload(i+333));
        cycle(1,1,1,0); // Reset wins over requests and flushes occupied FIFO.
        for(integer i=0;i<10000;i++) begin
            rng=next_random(rng);
            cycle(0,rng[0],rng[1],payload(rng));
        end
        repeat(DEPTH+1) cycle(0,0,1,0);
        if(queue.size()!=0 || writes!=reads+flushed || blocked_w==0 || blocked_r==0)
            $fatal(1,"Final accounting or boundary scenario missing");
        if(DEPTH>1 && simultaneous==0) $fatal(1,"No accepted simultaneous operations");
        $display("PASS FIFO width=%0d depth=%0d seed=%0d writes=%0d reads=%0d simultaneous=%0d flushed=%0d blocked_w=%0d blocked_r=%0d final=0",
                 DATA_WIDTH,DEPTH,SEED,writes,reads,simultaneous,flushed,blocked_w,blocked_r);
        $finish;
    end
    initial begin #300000; $fatal(1,"Regression timeout"); end
endmodule
