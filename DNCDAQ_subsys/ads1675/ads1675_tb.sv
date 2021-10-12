`timescale 1ns/10ps

module ads1675_sample_rate_2M_tb();
    bit rst_n,en;
    bit sclk,sclk_p,sclk_n;
    bit drdy,drdy_p,drdy_n;
    bit dout_p,dout_n;
    bit signed [23:0] data_recv;
    bit valid;
    bit signed [23:0] data_trans;
    initial forever #5 sclk=~sclk;
    initial #50 rst_n=1'b1;
    initial en=1'b1;
    initial begin
        forever begin
            data_trans=$random();
            @(posedge drdy);
        end
    end
    ads1675_model #(.W(48)) the_ads1675_model_Inst(
        sclk,rst_n,en,
        sclk_p,sclk_n,
        drdy_p,drdy_n,
        dout_p,dout_n,
        data_trans
    );
    IBUFDS drdy_buf (.O(drdy), .I(drdy_p), .IB(drdy_n));
    OBUFDS sclk_obufds_inst(
        .I(sclk),.O(sclk_p),.OB(sclk_n)
    );
    OBUFDS drdy_obufds_inst(
        .I(drdy),.O(drdy_p),.OB(drdy_n)
    );
    OBUFDS dout_obufds_inst(
        .I(dout),.O(dout_p),.OB(dout_n)
    );
    ads1675_source_32M_sample_rate_2M #(24) the_ads1675_source_32M_sample_rate_2M_Inst(
        .rst_n(rst_n),.en(en),
        .sclk_p(sclk_p),.sclk_n(sclk_n),
        .drdy_p(drdy_p),.drdy_n(drdy_n),
        .dout_p(dout_p),.dout_n(dout_n),
        .data(data_recv),
        .valid(valid)
    );
endmodule