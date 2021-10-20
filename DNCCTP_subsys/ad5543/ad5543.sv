`timescale 1ns/10ps

module ad5543 #(
    parameter integer DW = 16,
    parameter integer IFREQ = 96
)(
    input wire clk,rst_n,
    input wire en,
    (*mark_debug="true"*) input wire s_axis_tvalid,
    (*mark_debug="true"*) output logic s_axis_tready,
    (*mark_debug="true"*) input wire [DW-1:0] s_axis_tdata,
    (*dont_touch="yes",iob="true"*) output logic sclk,
    (*dont_touch="yes",iob="true"*) output logic sdi,
    (*dont_touch="yes",iob="true"*) output logic cs_n
);
    localparam integer INTERVAL = IFREQ/2;
    logic [$clog2(2*DW+1)-1:0] cnt;
    logic co;
    logic co33;
    logic [DW-1:0] shift_data;
    (*mark_debug="true"*) logic sclk_r,sdi_r,cs_n_r;
    counter #(INTERVAL) theCounter50 (clk,rst_n,en,co);
    assign sclk_r=~cnt[0] && !(cnt==32'd0);
    assign sdi_r=shift_data[DW-1];
    assign s_axis_tready=co;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            cnt<='0;
        end
        else if(en) begin
            if(co) begin
                cnt<=32'd1;
            end
            else if(cnt==32'd33) begin
                cnt<=32'd0;
            end
            else if(cnt==32'd0) begin
                cnt<=32'd0;
            end
            else begin
                cnt=cnt+32'd1;
            end
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            shift_data<='0;
        end
        else if(en) begin
            if(co) begin
                shift_data<=s_axis_tdata;
            end
            else if(sclk_r) begin
                shift_data<={shift_data[DW-2:0],1'b0};
            end
        end
    end
    always_ff @( posedge clk ) begin
        co33<=cnt==32'd33;
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            cs_n_r<=1'b1;
        end
        else if(en) begin
            if(co) begin
                cs_n_r<=1'b0;
            end
            else if(co33) begin
                cs_n_r<=1'b1;
            end
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            sclk<=1'b0;
            sdi<=1'b0;
            cs_n<=1'b1;
        end
        else if(en) begin
            sclk<=sclk_r;
            sdi<=sdi_r;
            cs_n<=cs_n_r;
        end
    end
    /*
    assign sclk=sclk_r;
    assign sdi=sdi_r;
    assign cs_n=cs_n_r;
    */
endmodule