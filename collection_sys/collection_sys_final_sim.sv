`timescale 1ns/10ps

module ADS1675_gen_sim #(
    parameter integer DW = 24
)(
    output logic sclk,drdy,dout,
    input wire dr0,dr1,dr2,
    input wire fpath,ll_cfg,lvds,clk_sel,
    input wire cs_n,start,pown,
    input wire signed [DW-1:0] data_trans,
    output logic sclk_clk_p,sclk_clk_n,
    output logic drdy_clk_p,drdy_clk_n,
    output logic dout_clk_p,dout_clk_n
);
    logic signed [DW-1:0] shift_data;
    logic co24,co3;
    bit sclk_copy;
    initial forever #5 sclk_copy=~sclk_copy;
    assign sclk=sclk_copy;
    counter #(24) counter24(sclk,1'b1,1'b1,co24);
    counter #(3)  counter3 (sclk,~co24,1'b1,co3);

    always_ff @( posedge sclk ) begin
        if(co24) begin
            drdy<=1'b1;
        end
        else if(drdy && co3) begin
            drdy<=1'b0;
        end
    end

    always_ff @( posedge sclk ) begin
        if(co24) begin
            shift_data<=data_trans;
        end
        else begin
            shift_data<={shift_data[DW-2:0],1'b0};
        end
    end
    assign dout=shift_data[DW-1];

    
endmodule

module ADS1675_gen_sim_tb;
    bit aclk;
    bit dr0,dr1,dr2;
    bit fpath,ll_cfg,lvds,clk_sel;
    bit cs_n,start,pown;
    bit sclk,drdy,dout;
    bit sclk_clk_p,sclk_clk_n;
    bit drdy_clk_p,drdy_clk_n;
    bit dout_clk_p,dout_clk_n;
    bit signed [23:0] goden_data[$];
    bit signed [23:0] recev_data[$];
    bit signed [23:0] data_trans,data_recv;
    bit valid;

    initial begin
        goden_data={24'd1,24'd2};   // ADS1675 module has two round of spare data.
    end
    assign aclk=sclk;

    ADS1675_gen_sim #(.DW(24)) the_ADS1675_gen_sim_tb_inst(
        sclk,drdy,dout,
        dr0,dr1,dr2,
        fpath,ll_cfg,lvds,clk_sel,
        cs_n,start,pown,
        data_trans,
        sclk_clk_p,sclk_clk_n,
        drdy_clk_p,drdy_clk_n,
        dout_clk_p,dout_clk_n
    );

    ADS1675 #(24) the_ADS1675_sim_tb_inst(
        aclk,1'b1,1'b1,
        sclk,drdy,dout,
        dr0,dr1,dr2,
        fpath,ll_cfg,lvds,clk_sel,
        cs_n,start,pown,
        data_recv,
        valid
    );

    always_ff @( posedge aclk ) begin
        if(valid) begin
            recev_data.push_back(data_recv);
        end
    end

    initial begin
        automatic int round=100;
        fork
            begin
                forever begin
                    @(negedge drdy);
                    data_trans=$random();
                    goden_data.push_back(data_trans);
                end
            end
            begin
                for(int i=0;i<round;i++)
                begin
                    automatic bit signed [23:0] goden,actual;
                    wait(goden_data.size()!=0 && recev_data.size()!=0);
                    goden=goden_data.pop_front();
                    actual=recev_data.pop_front();
                    if(goden!=actual && i>1) begin
                        $display("goden:%x, actual:%x.GODEN ACTUAL MISMATCH",goden,actual);
                    end
                end
            end
        join_any
        $display("ROUND:%0d,ALL TEST PASS",round);
        $finish;
    end
endmodule

module collection_sys_final_sim #(

)(

);

endmodule