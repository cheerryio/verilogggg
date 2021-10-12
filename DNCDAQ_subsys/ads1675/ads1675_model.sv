`timescale 1ns/10ps

module ads1675_model #(
    parameter int W=48
)(
    input wire sclk,rst_n,en,
    output logic sclk_p,sclk_n,
    output logic drdy_p,drdy_n,
    output logic dout_p,dout_n,
    input wire signed [23:0] data_trans
);
    logic co,co3;
    logic signed [W-1:0] shift_data;
    logic drdy,dout;

    counter #(W) the_counter(sclk,rst_n,en,co);
    counter #(3) the_counter3(sclk,~co,en,co3);
    always_ff @( posedge sclk ) begin
        if(co) begin
            drdy<=1'b1;
        end
        else if(drdy && co3) begin
            drdy<=1'b0;
        end
    end
    always_ff @( posedge sclk ) begin
        if(co) begin
            shift_data<={data_trans,{(W-24){1'b0}}};
        end
        else begin
            shift_data<={shift_data[0+:W-1],1'b0};
        end
    end
    assign dout=shift_data[W-1];

    OBUFDS sclk_obufds_inst (
        .I(sclk),.O(sclk_p),.OB(sclk_n)
    );
    OBUFDS drdy_obufds_inst (
        .I(drdy),.O(drdy_p),.OB(drdy_n)
    );
    OBUFDS dout_obufds_inst (
        .I(dout),.O(dout_p),.OB(dout_n)
    );
endmodule
