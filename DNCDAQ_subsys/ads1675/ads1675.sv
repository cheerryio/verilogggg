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

module ads1675_source_16M_sample_rate_2M #(
    parameter int DW = 24,
    parameter string DIFF_TERM="TRUE"
)(
    (*dont_touch="yes",iob="true"*) input wire sclk_p,
    (*dont_touch="yes",iob="true"*) input wire sclk_n,
    (*dont_touch="yes",iob="true"*) input wire drdy_p,
    (*dont_touch="yes",iob="true"*) input wire drdy_n,
    (*dont_touch="yes",iob="true"*) input wire dout_p,
    (*dont_touch="yes",iob="true"*) input wire dout_n,
    output wire sclk,
    input wire areset_n,en,
    // configure
    output wire dr0,dr1,dr2,
    output wire fpath,ll_cfg,lvds,clk_sel,
    // control
    output wire cs_n,start,pown,
    (*mark_debug="true"*) output logic signed [DW-1:0] data,
    (*mark_debug="true"*) output logic valid
);
    wire drdy;
    wire dout;
    IBUFGDS #(.DIFF_TERM(DIFF_TERM), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("LVDS_25")) sclk_buf (.O(sclk), .I(sclk_p), .IB(sclk_n));
    IBUFDS  #(.DIFF_TERM(DIFF_TERM), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("LVDS_25")) drdy_buf (.O(drdy), .I(drdy_p), .IB(drdy_n));
    IBUFDS  #(.DIFF_TERM(DIFF_TERM), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("LVDS_25")) din_buf  (.O(dout ), .I(dout_p), .IB(dout_n));
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
    assign pown   =1'b1;
    assign start  =1'b1;

    (*mark_debug="true"*) logic [DW-1:0] shift_data;
    (*mark_debug="true"*) logic [1:0] drdy_dly;
    (*mark_debug="true"*) logic dout_r;
    always_ff @( posedge sclk ) begin
        drdy_dly<={drdy_dly[0],drdy};
        dout_r<=dout;
    end
    always_ff @( posedge sclk ) begin
        if(!areset_n) begin
            shift_data <= '0;
        end
        else if(en) begin
            shift_data <= {shift_data[0+:DW-1], dout_r};
        end
    end
    (*mark_debug="true"*) wire drdy_rising=drdy_dly==2'b01;
    always_ff @( posedge sclk ) begin
        if(!areset_n) begin 
            data <= '0;
        end
        else if(en) begin
            if(drdy_rising) begin 
                data <= shift_data[DW-1-:24];
            end
        end
    end
    always_ff @( posedge sclk ) begin
        if(!areset_n) begin 
            valid <= 1'b0;
        end
        else if(en) begin
            if(drdy_rising) begin 
                valid <= 1'b1;
            end
            else begin
                valid <= 1'b0;
            end
        end
    end
endmodule

module ads1675_source_32M_sample_rate_2M #(
    parameter integer DW=24,
    parameter integer SDW=48,
    parameter string DIFF_TERM="TRUE",
    parameter integer DROP=50
)(
    (*dont_touch="yes",iob="true"*) input wire sclk_p,
    (*dont_touch="yes",iob="true"*) input wire sclk_n,
    (*dont_touch="yes",iob="true"*) input wire drdy_p,
    (*dont_touch="yes",iob="true"*) input wire drdy_n,
    (*dont_touch="yes",iob="true"*) input wire dout_p,
    (*dont_touch="yes",iob="true"*) input wire dout_n,
    output wire sclk,
    input wire rst_n,
    (*mark_debug="true"*) input wire en,
    // configure
    output wire dr0,dr1,dr2,
    output wire fpath,ll_cfg,lvds,clk_sel,
    // control
    output wire cs_n,start,pown,
    (*mark_debug="true"*) output logic signed [DW-1:0] data,
    (*mark_debug="true"*) output logic valid
);
    logic [$clog2(DROP)-1:0] valid_cnt;
    (*mark_debug="true"*) wire drdy;
    (*mark_debug="true"*) wire dout;
    IBUFGDS #(.DIFF_TERM(DIFF_TERM), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("LVDS_25")) sclk_buf (.O(sclk), .I(sclk_p), .IB(sclk_n));
    IBUFDS  #(.DIFF_TERM(DIFF_TERM), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("LVDS_25")) drdy_buf (.O(drdy), .I(drdy_p), .IB(drdy_n));
    IBUFDS  #(.DIFF_TERM(DIFF_TERM), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("LVDS_25")) din_buf  (.O(dout ), .I(dout_p), .IB(dout_n));
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
    assign pown   =1'b1;
    assign start  =en;

    (*mark_debug="true"*) logic [SDW-1:0] shift_data;
    (*mark_debug="true"*) logic [1:0] drdy_dly;
    (*mark_debug="true"*) logic dout_r;
    always_ff @( posedge sclk ) begin
        drdy_dly<={drdy_dly[0],drdy};
        dout_r<=dout;
    end
    always_ff @( posedge sclk ) begin
        if(!rst_n) begin
            shift_data<='0;
        end
        else if(en) begin
            shift_data<={shift_data[0+:SDW-1], dout_r};
        end
    end
    wire drdy_rising=drdy_dly==2'b01;
    always_ff @( posedge sclk ) begin
        if(!rst_n) begin 
            data<='0;
        end
        else if(en) begin
            if(drdy_rising) begin
                data<=shift_data[SDW-1-:DW];
            end
        end
    end
    always_ff @( posedge sclk ) begin
        if(!rst_n) begin
            valid_cnt<='0;
        end
        else if(en) begin
            if(valid_cnt<DROP-1 && drdy_rising) begin
                valid_cnt=valid_cnt+1'b1; 
            end
        end
    end
    always_ff @( posedge sclk ) begin
        if(!rst_n) begin 
            valid <= 1'b0;
        end
        else if(en) begin
            if(drdy_rising && valid_cnt==DROP-1) begin
                valid <= 1'b1;
            end
            else begin
                valid <= 1'b0;
            end
        end
    end
endmodule
