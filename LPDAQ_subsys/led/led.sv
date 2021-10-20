`timescale 1ns/10ps

module led #(
    parameter int FREQ=100000000
)(
    input wire clk,rst_n,
    (*mark_debug="true"*) input wire en,
    (*mark_debug="true"*) output logic led_out
);
    (*mark_debug="true"*) logic co;
    counter #(FREQ) the_counter_Inst(clk,rst_n,1'b1,co);
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            led_out<=1'b0;
        end
        else if(co) begin
            led_out<=(~led_out)&en;
        end
    end
endmodule