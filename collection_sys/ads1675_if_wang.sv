`timescale 1ns / 1ps
`default_nettype none

module ads1675_if #(
    parameter int LLCFG = 0   ,    // 0 - single cyc(override FPATH to 1); 1 - fast response
    parameter int FPATH = 0   ,    // 0 - wide band; 1 - low lantency
    parameter int DR    = 5   ,    // fs = 125ks/s * 2**DR (@ 32MHz Osc)
    parameter int FLEN  = 4000,
    parameter string DIFF_TERM = "FALSE"
)(
    (* dont_touch = "yes", iob = "true" *) input  wire  adc_sclk_p,
    (* dont_touch = "yes", iob = "true" *) input  wire  adc_sclk_n,
    (* dont_touch = "yes", iob = "true" *) input  wire  adc_drdy_p,
    (* dont_touch = "yes", iob = "true" *) input  wire  adc_drdy_n,
    (* dont_touch = "yes", iob = "true" *) input  wire  adc_dout_p,
    (* dont_touch = "yes", iob = "true" *) input  wire  adc_dout_n,
    output logic adc_csn   ,
    output logic adc_start ,
    output logic adc_pdn   ,

    output wire  [2:0] adc_dr    ,
    output wire        adc_fpath ,
    output wire        adc_llcfg ,
    output wire        adc_lvds  ,
    output wire        adc_clksel,

    input  wire        ctrl_pd   ,
    input  wire        ctrl_start,
    output wire        overflow  ,

    output wire                aclk       ,
    input  wire                aresetn    ,
    output logic signed [23:0] axis_tdata ,
    output logic               axis_tlast ,
    output logic               axis_tvalid,
    input  wire                axis_tready
);
    assign adc_clksel = 1'b0;
    assign adc_lvds   = 1'b0;
    assign adc_llcfg  = LLCFG[0];
    assign adc_fpath  = FPATH[0];
    assign adc_dr     = DR[2:0];

    wire drdy;
    wire din;
    IBUFGDS #(.DIFF_TERM(DIFF_TERM), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("LVDS_25")) aclk_buf (.O(aclk), .I(adc_sclk_p), .IB(adc_sclk_n));
    IBUFDS  #(.DIFF_TERM(DIFF_TERM), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("LVDS_25")) drdy_buf (.O(drdy), .I(adc_drdy_p), .IB(adc_drdy_n));
    IBUFDS  #(.DIFF_TERM(DIFF_TERM), .IBUF_LOW_PWR("TRUE"), .IOSTANDARD("LVDS_25")) din_buf  (.O(din ), .I(adc_dout_p), .IB(adc_dout_n));

    (* mark_debug = "true" *) logic [1:0] drdy_r;
    (* mark_debug = "true" *) logic       din_r;
    always_ff @( posedge aclk ) begin
        drdy_r <= {drdy_r[0], drdy};
        din_r  <= din;
    end

    localparam int SRW = 24*(2**(5-DR));
    (* mark_debug = "true" *) logic [SRW-1 : 0] sr;
    always_ff @( posedge aclk ) begin
        if(~aresetn) sr <= '0;
        else         sr <= {sr[0 +: SRW-1], din_r};
    end

    (* mark_debug = "true" *) wire drdy_rising = drdy_r == 2'b01;
    always_ff @( posedge aclk ) begin : proc_tdata
        if(~aresetn)         axis_tdata <= '0;
        else if(drdy_rising) axis_tdata <= sr[SRW-1 -: 24];
    end

    always_ff @( posedge aclk ) begin : proc_tvalid
        if(~aresetn)         axis_tvalid <= 1'b0;
        else if(drdy_rising) axis_tvalid <= 1'b1;
        else if(axis_tready) axis_tvalid <= 1'b0;
    end

    (* mark_debug = "true" *) logic [$clog2(FLEN)-1 : 0] fcnt;
    always_ff @( posedge aclk ) begin : proc_fcnt
        if(~aresetn) begin
            fcnt <= '0;
        end
        else if(drdy_rising) begin
            if(fcnt < FLEN-1) fcnt <= fcnt + 1'b1;
            else              fcnt <= '0;
        end
    end

    assign axis_tlast = fcnt == FLEN - 1;

    assign overflow = axis_tvalid && ~axis_tready && drdy_rising;

    always_ff @( posedge aclk ) begin
        if(~aresetn) begin
//            adc_csn   <= 1'b1;
            adc_start <= 1'b0;
//            adc_pdn   <= 1'b1;
        end
        else begin
//            adc_csn   <= 1'b0;
            adc_start <= ctrl_start;
//            adc_pdn   <= ~ctrl_pd;
        end
    end
    assign adc_pdn = ~ctrl_pd;
    assign adc_csn = 1'b0;

endmodule

`default_nettype wire
