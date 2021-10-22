`timescale 1ns/10ps

module pcf8563_if #(
    parameter int DIV=500,
    parameter int GAP=100000000
)(
    input wire clk,rst_n,en,
    input wire start,
    output logic [7:0] rdata,
    output logic done,

    input wire scl_i,
    output logic scl_o,
    output logic scl_t,
    input wire sda_i,
    output logic sda_o,
    output logic sda_t
);
    wire [6:0] dev_addr=7'h38;
    logic [7:0] reg_addr;
    (*mark_debug="true"*) logic co,co_dly;
    logic w;
    logic [7:0] wd;
    counter #(GAP) the_counter(clk,rst_n,en,co);
    logic [1:0] led;
    logic in_cycle;
    always_ff @( posedge clk ) begin
        co_dly<=co;
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            w<=1'b0;
            in_cycle<=1'b0;
            led<='0;
        end
        else if(co) begin
            if(led==2'd0) begin
                led<=2'd1;
                w<=1'b1;
                wd<=(~3'b001)<<5;
                reg_addr<=8'h01;
            end
            else if(led==1'd1) begin
                led<=2'd2;
                w<=1'b1;
                wd<=(~3'b010)<<5;
                reg_addr<=8'h01;
            end
            else if(led==2'd2) begin
                led<=2'd3;
                w<=1'b1;
                wd<=(~3'b100)<<5;
                reg_addr<=8'h01;
            end
            else if(led==2'd3) begin
                led<=2'd0;
                w<=1'b1;
                wd<=8'h1f;
                reg_addr<=8'h03;
            end
        end
    end
    iic_master #(DIV) the_iic_master_Inst(
        clk,rst_n,en,
        co_dly,
        dev_addr,reg_addr,
        w,wd,
        rdata,
        done,
        scl_i,scl_o,scl_t,
        sda_i,sda_o,sda_t
    );
endmodule