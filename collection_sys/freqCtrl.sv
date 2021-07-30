`timescale 1ns/10ps

module freqCtrl_tb #(

)(

);
    logic clk,rst_n,en;
    initial begin
        clk=0;
        en=1;
        forever #50 clk=~clk;
    end
    initial begin
        rst_n=0;
        #100 rst_n=1;
    end
    logic [2:0] word;
    always_ff @( posedge clk ) begin
        if(!rst_n) word <= '0;
        else if(en)
        begin
            if(word<5) begin word<=word+1; end
            else begin word<='0; end
        end
    end
    logic signed [31:0] freq;
    freqCtrl #()
    theFreqCtrlTbInst(clk,rst_n,en,word,freq);
endmodule

module freqCtrl #(

)(
    input wire clk,rst_n,en,
    input wire [2:0] word,
    output logic signed [31:0] freq
);
    always_comb begin
        case(word)
        3'b000:
            freq = 32'h0a000000;
        3'b001:
            freq = 32'h0b000000;
        3'b010:
            freq = 32'h0c000000;
        3'b011:
            freq = 32'h0d000000;
        3'b100:
            freq = 32'h0e000000;
        3'b101:
            freq = 32'h0f000000;
        default:
            freq = 32'h00000000;
        endcase
    end
endmodule
