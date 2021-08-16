`timescale 1ns/10ps

module ADS1675_gen_sim #(
    parameter integer DW = 24
)(
    input wire dr0,dr1,dr2,
    input wire fpath,ll_cfg,lvds,clk_sel,
    input wire cs_n,start,pown,
    input wire signed [DW-1:0] data_trans,
    output logic sclk,drdy,dout,
    output logic sclk_clk_p,sclk_clk_n,
    output logic drdy_clk_p,drdy_clk_n,
    output logic dout_clk_p,dout_clk_n
);
    bit sclk,drdy,dout;
    logic signed [DW-1:0] data;
    logic co24,co3;
    initial begin
        forever #5ns sclk=~sclk;
    end
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
            data<=data_trans;
        end
        else begin
            data<={data[DW-2:0],1'b0};
        end
    end

    always_ff @( posedge sclk ) begin
        dout<=data[DW-1];
    end
endmodule

module ADS1675_gen_sim_tb;
    bit dr0,dr1,dr2;
    bit fpath,ll_cfg,lvds,clk_sel;
    bit cs_n,start,pown;
    bit sclk,drdy,dout;
    bit sclk_clk_p,sclk_clk_n;
    bit drdy_clk_p,drdy_clk_n;
    bit dout_clk_p,dout_clk_n;
    bit signed [23:0] goden_data[$];
    bit signed [23:0] data_recv;
    bit valid;

    ADS1675_gen_sim the_ADS1675_gen_sim_tb_inst #(.DW(24))(
        dr0,dr1,dr2,
        fpath,ll_cfg,lvds,clk_sel,
        cs_n,start,pown,
        sclk,drdy,dout,
        sclk_clk_p,sclk_clk_n,
        drdy_clk_p,drdy_clk_n,
        dout_clk_p,dout_clk_n
    );

    ADS1675 the_ADS1675_sim_tb_inst(
        sclk,1'b1,1'b1,
        dr0,dr1,dr2,
        fpath,ll_cfg,lvds,clk_sel,
        cs_n,start,pown,
        sclk,drdy,dout,
        data_recv,
        valid
    );

endmodule

module down_conversion_sys_final_sim #(

)(

);

endmodule