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

)(
    input wire aclk,areset_n,en,
    // configure
    output wire dr0,dr1,dr2,
    output wire fpath,ll_cfg,lvds,clk_sel,
    // control
    output wire cs_n,start,pown,
    input wire sclk,dout,drdy,
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

    localparam integer DW = 23;

    localparam integer BEFORE_START = 2'd0;
    localparam integer IDLE         = 2'd1;
    localparam integer RETREIVING    = 2'd2;
    logic [1:0] state;
    logic [DW-1:0] shift_data,data;
    logic [$clog2(DW)-1:0] cnt;

    always_ff @( posedge drdy ) begin
        if(!areset_n) begin
            state<=BEFORE_START;
        end
        else if(state==BEFORE_START)
        begin
            state<=IDLE;
        end
        else if(state==IDLE)
        begin
            state<=RETREIVING;
        end
        else if(state==RETREIVING)
        begin
            // ignore
            state<=state;
        end 
    end

    always_ff @( negedge sclk ) begin
        if(state==RETREIVING)
        begin
            shift_data<={shift_data[21:0],dout};
        end
    end

    always_ff @( posedge sclk ) begin
        if(!areset_n)
        begin
            cnt<='0;
        end
        else if(state==RETREIVING)
        begin
            cnt<=cnt+1;
        end
        else
        begin
            cnt<='0;
        end
    end

    always_ff @( posedge sclk ) begin
        if(!areset_n) begin
            data<='0;
        end
        else if(state==RETREIVING && cnt==DW)
        begin
            data<=shift_data;
        end
    end

    assign valid=cnt==DW;

endmodule