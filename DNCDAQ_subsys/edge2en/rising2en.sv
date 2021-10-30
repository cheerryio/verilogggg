`timescale 1ns/10ps

module rising2en #( parameter SYNC_STG = 1 )(
    input wire clk,
    input wire in,
    output logic en
);
    logic [SYNC_STG : 0] dly;
    always@(posedge clk) begin
        dly <= {dly[SYNC_STG - 1 : 0], in};
    end
    assign en = (SYNC_STG ? dly[SYNC_STG -: 2] : {dly, in}) == 2'b01;
endmodule