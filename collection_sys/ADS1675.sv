`timescale 1ns/10ps

/*
* USAGE DRDY:
* The rising edge of DRDY out, shift clock, 
* and data ready signals are output on should be used as an indicator to start the data the differential pairs of pins DOUT/DOUT, 
* capture with the serial shift clock.
*/
/*
* The device gives out a DRDY pulse (regardless
* OTRA can be used in feedback loops to correct input of the status of the START signal) to indicate that the
* over-range conditions quickly. lock is complete. Disregard the data associated with
* this DRDY pulse. After this DRDY pulse, it is
* SERIAL recommended that the user toggle the start signal INTERFACE
* before starting to capture data.
*/

module ADS1675_2M_SAMPLE_RATE_tb;
    bit clk,rst_n,en;
    bit sclk,drdy,dout;
    bit aclk;
    initial begin
        forever #5 clk=~clk;
    end
    initial begin
        forever #20 aclk=~aclk;
    end
    initial begin
        rst_n=1'b0;
        #50 rst_n=1'b1;
    end
    initial begin en=1'b1; end
    bit signed [23:0] data_trans;
    initial begin
        forever begin
            data_trans=$random();
            @(posedge drdy); 
        end
    end

    ADS1675_32M_SOURCE_2M_SAMPLE_RATE_MODEL theADS1675_32M_SOURCE_2M_SAMPLE_RATE_MODEL_Inst(
        clk,rst_n,en,
        sclk,drdy,dout,
        data_trans
    );
    bit signed [23:0] data_recv;
    bit valid;
    ADS1675_2M_SAMPLE_RATE #(24) theADS1675_2M_SAMPLE_RATE(
        .aclk(aclk),.areset_n(rst_n),.en(en),
        .sclk(sclk),.drdy(drdy),.dout(dout),
        .data(data_recv),
        .valid(valid)
    );
endmodule

module ADS1675_32M_SOURCE_2M_SAMPLE_RATE_MODEL #(

)(
    input wire sclk_in,rst_n,en,
    output logic sclk,drdy,dout,
    input wire signed [23:0] data_trans
);
    assign sclk=sclk_in;
    logic co48,co3;
    logic signed [23:0] shift_data;

    counter #(48) counter24(sclk,rst_n,en,co48);
    counter #(3)  counter3 (sclk,~co48,en,co3);
    always_ff @( posedge sclk ) begin
        if(co48) begin
            drdy<=1'b1;
        end
        else if(drdy && co3) begin
            drdy<=1'b0;
        end
    end
    always_ff @( posedge sclk ) begin
        if(co48) begin
            shift_data<=data_trans;
        end
        else begin
            shift_data<={shift_data[22:0],1'b0};
        end
    end
    assign dout=shift_data[23];
endmodule

module ADS1675_4M_SAMPLE_RATE #(
    parameter integer DW = 24
)(
    input wire aclk,areset_n,en,
    input wire sclk,drdy,dout,
    // configure
    output wire dr0,dr1,dr2,
    output wire fpath,ll_cfg,lvds,clk_sel,
    // control
    output wire cs_n,start,pown,
    output logic signed [DW-1:0] data,
    output logic valid
);
    assign dr0    =1'b1;
    assign dr1    =1'b0;
    assign dr2    =1'b1;
    assign fpath  =1'b0;
    assign ll_cfg =1'b1;
    // OPTIONAL CONFIGURE START
    assign lvds   =1'b0;
    assign clk_sel=1'b0;
    // OPTIONAL CONFIGURE END
    assign cs_n   =1'b0;
    assign start  =1'b1;
    assign pown   =1'b1;

    logic [DW-1:0] shift_data;
    logic [1:0] drdy_dly;

    always_ff @( posedge aclk ) begin
        if(!areset_n) begin
            drdy_dly<='0;
        end
        else if(en) begin
            drdy_dly<={drdy_dly[0],drdy};
        end
    end
    assign valid=~drdy_dly[1] & drdy_dly[0];

    always_ff @( negedge sclk ) begin
        if(!areset_n) begin
            shift_data<='0;
        end
        else if(en) begin
            shift_data<={shift_data[DW-2:0],dout};
        end
    end

    always_ff @( posedge drdy ) begin
        if(!areset_n) begin
            data<='0;
        end
        else if(en) begin
            data<=shift_data;
        end
    end
endmodule

module ADS1675_2M_SAMPLE_RATE #(
    parameter integer DW = 24
)(
    input wire aclk,areset_n,en,
    input wire sclk,drdy,dout,
    // configure
    output wire dr0,dr1,dr2,
    output wire fpath,ll_cfg,lvds,clk_sel,
    // control
    output wire cs_n,start,pown,
    output logic signed [DW-1:0] data,
    output logic valid
);

    assign dr0    =1'b0;
    assign dr1    =1'b0;
    assign dr2    =1'b1;
    assign fpath  =1'b0;
    assign ll_cfg =1'b1;
    // OPTIONAL CONFIGURE START
    assign lvds   =1'b0;
    assign clk_sel=1'b0;
    // OPTIONAL CONFIGURE END
    assign cs_n   =1'b0;
    assign start  =1'b1;
    assign pown   =1'b1;

    logic [DW-1:0] shift_data;
    logic mask;
    logic co24;
    //drive mask
    always_ff @( negedge sclk ) begin
        if(!areset_n) begin
            mask<=1'b0;
        end
        else if(en) begin
            if(drdy) begin
                mask<=1'b1;
            end
            else if(co24) begin
                mask<=1'b0;
            end
        end
    end
    counter #(.N(24),.IS_NEGEDGE(1)) theCounter24(sclk,mask,mask,co24);
    always_ff @( negedge sclk ) begin
        if(!areset_n) begin
            shift_data<='0;
        end
        else if(en) begin
            if(!mask && drdy) begin
                shift_data<={shift_data[DW-2:0],dout};
            end
            else if(co24) begin
                data<=shift_data;
            end
            else if(mask) begin
                shift_data<={shift_data[DW-2:0],dout};
            end
        end
    end

    // co23信号 从sclk跨时钟域到aclk，快到慢
    logic signala,signalb;
    logic [1:0] shift_a,shift_b;
    always_ff @( negedge sclk ) begin
        if(!areset_n) begin
            signala<=1'b0;
        end
        else if(en) begin
            if(co24) begin
                signala<=1'b1;
            end
            else if(shift_b[1]) begin
                signala<=1'b0;
            end
        end
    end
    always_ff @( posedge aclk ) begin
        if(!areset_n) begin
            signalb<=1'b0;
        end
        else if(en) begin
            signalb<=signala;
        end
    end
    always_ff @( posedge aclk ) begin
        if(!areset_n) begin
            shift_b<='0;
        end
        else if(en) begin
            shift_b<={shift_b[0],signalb};
        end
    end
    always_ff @( negedge sclk ) begin
        if(!areset_n) begin
            shift_a<='0;
        end
        else if(en) begin
            shift_a<={shift_a[0],signalb};
        end
    end
    assign valid=~shift_b[1]&shift_b[0];
endmodule