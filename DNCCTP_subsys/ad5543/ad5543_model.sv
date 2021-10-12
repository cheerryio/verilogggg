`timescale 1ns/10ps

module ad5543_model #(
    parameter integer DW = 16
)(
    input wire sclk,
    input wire sdi,
    input wire cs_n,
    output logic [DW-1:0] data
);
    logic [DW-1:0] shift_data;
    always_ff @( posedge sclk ) begin
        if(!cs_n) begin
            shift_data<={shift_data[DW-2:0],sdi}; 
        end
    end

    always_ff @( posedge cs_n ) begin
        data<=shift_data;
    end
endmodule