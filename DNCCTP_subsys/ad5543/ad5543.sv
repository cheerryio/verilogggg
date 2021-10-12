`timescale 1ns/10ps

module ad5543 #(
    parameter integer DW = 16,
    parameter integer IFREQ = 96
)(
    input wire s_axis_aclk,s_axis_aresetn,
    input wire en,
    input wire s_axis_tvalid,
    output logic s_axis_tready,
    (*mark_debug="true"*) input wire [DW-1:0] s_axis_tdata,
    (*mark_debug="true"*) output logic sclk,sdi,cs_n
);
    localparam integer INTERVAL = IFREQ/2;
    logic [$clog2(2*DW+1)-1:0] cnt;
    logic co;
    logic co33;
    logic [DW-1:0] shift_data;
    counter #(INTERVAL) theCounter50 (s_axis_aclk,s_axis_aresetn,en,co);
    assign sclk=~cnt[0] && !(cnt==32'd0);
    assign sdi=shift_data[DW-1];
    always_ff @( posedge s_axis_aclk ) begin
        if(!s_axis_aresetn) begin
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
    always_ff @( posedge s_axis_aclk ) begin
        if(!s_axis_aresetn) begin
            shift_data<='0;
        end
        else if(en) begin
            if(co) begin
                shift_data<=s_axis_tdata;
            end
            else if(sclk) begin
                shift_data<={shift_data[DW-2:0],1'b0};
            end
        end
    end
    always_ff @( posedge s_axis_aclk ) begin
        if(!s_axis_aresetn) begin
            s_axis_tready<=1'b0;
        end
        else if(en) begin
            if(co) begin
                s_axis_tready<=1'b1;
            end
            else begin
                s_axis_tready<=1'b0;
            end
        end
    end
    always_ff @( posedge s_axis_aclk ) begin
        co33<=cnt==32'd33;
    end
    always_ff @( posedge s_axis_aclk ) begin
        if(!s_axis_aresetn) begin
            cs_n<=1'b1;
        end
        else if(en) begin
            if(co) begin
                cs_n<=1'b0;
            end
            else if(co33) begin
                cs_n<=1'b1;
            end
        end
    end
endmodule
