`timescale 1ns/10ps

module str_reg_slice #(
    parameter integer DW = 24
)(
    input wire clk,rst_n,
    input wire [DW-1:0] idata,
    input wire ilast,
    input wire ivalid,
    output logic iready,
    output logic [DW-1:0] odata,
    output logic olast,
    output logic ovalid,
    input wire oready
);
    wire ish=ivalid&iready;
    wire osh=ovalid&oready;
    logic [DW:0] buffer[2];
    logic wp,rp;
    logic [1:0] dc;
    assign iready=dc<2'd2;
    assign ovalid=dc>2'd0;
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            wp<=1'b0;
            rp<=1'b0;
        end
        else begin
            if(ish) wp<=~wp;
            else if(osh) rp<=~rp;
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            dc<=2'd0;
        end
        else begin
            case ({ish,osh})
                2'b10:  dc<=dc+2'd1;
                2'b01:  dc<=dc-2'd1;
            endcase
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            buffer<={'0,'0};
        end
        else begin
            if(ish) begin
                buffer[wp]<={ilast,idata};
            end
        end
    end
    assign {olast,odata}=buffer[rp];
endmodule