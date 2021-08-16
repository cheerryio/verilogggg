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
module ADS1675 #(
    parameter integer DW = 24
)(
     input wire aclk,areset_n,en,
    // configure
     output wire dr0,dr1,dr2,
     output wire fpath,ll_cfg,lvds,clk_sel,
    // control
     output wire cs_n,start,pown,
     input wire sclk,dout,drdy,
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
            drdy_dly<= '0;
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