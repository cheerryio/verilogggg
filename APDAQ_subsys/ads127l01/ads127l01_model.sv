`timescale 1ns/10ps

module ads127l01_512k_master_fsync_model #(

)(
    input wire clk,rst_n,en,
    input wire [23:0] data,
    output logic sck,dout,fsync
);
    logic co32;
    logic [31:0] shift_data;
    logic [$clog2(16)-1:0] fsync_cnt;
    initial begin
        sck=1'b0;
        forever begin
            repeat(4) @(posedge clk);
            sck=~sck;
        end
    end
    counter #(32) the_counter32(sck,rst_n,1'b1,co32);
    assign fsync=(fsync_cnt!=1'b0);
    always_ff @( posedge sck ) begin
        if(!rst_n) begin
            fsync_cnt<='0;
        end
        else if(en) begin
            if(co32) begin
                fsync_cnt=1'b1;
            end
            else if(fsync_cnt==15) begin
                fsync_cnt=1'b0;
            end
            else if(fsync_cnt!=1'b0) begin
                fsync_cnt=fsync_cnt+1;
            end
        end
    end
    assign dout=shift_data[31];
    always_ff @( negedge sck ) begin
        if(!rst_n) begin
            shift_data<='0;
        end
        else if(en) begin
            if(co32) begin
                shift_data<={data,{8{1'b0}}};
            end
            else begin
                shift_data<={shift_data[0+:31],1'b0};
            end
        end
    end

endmodule