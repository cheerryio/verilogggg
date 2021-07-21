`timescale 1ps/1ps

module segDisplayCounter #(
    parameter integer N = 64
)(
    input wire clk,rst_n,en,
    output logic co
);
    logic [$clog2(N)-1:0] cnt;
    //drive cnt
    always_ff @( posedge clk ) begin
        if(!rst_n)
        begin
            cnt <= '0;
        end
        else if(en)
        begin
            if(cnt < N - 1)
            begin
                cnt <= cnt + 1;
            end
            else
            begin
                cnt <= '0;
            end
        end
    end
    // drive co
    assign co = (cnt == N - 1);
endmodule

module segDisplay #(
    parameter integer CLK_TO_SEGFREQ = 8192
)(
    input wire clk,rst_n,
    input wire [31:0] data,
    output logic [7:0] segments,
    output logic [7:0] anodes
);
    logic [2:0] index;
    logic [7:0] digits[0:15] = '{8'hc0,8'hf9,8'ha4,8'hb0,8'h99,8'h92,8'h82,8'hf8,8'h80,8'h90,8'h88,8'h83,8'hc6,8'ha1,8'h86,8'h8e};
    logic index_co;
    // drive segments
    integer number;
    assign number = (data >> index*4) & 4'hf;
    assign segments = digits[number];
    // drive index_co
    segDisplayCounter #(.N(CLK_TO_SEGFREQ))
    theIndexCounter(
        clk,1'b1,1'b1,
        index_co
    );
    // drive index
    always_ff @( posedge clk ) begin
        if(!rst_n)
        begin
            index <= '0;
        end
        else
        begin
            if(index_co)
            begin
                if(index < 7)
                begin
                    index <= index + 1;
                end
                else
                begin
                    index <= '0;
                end
            end
            else
            begin
                index <= index;
            end
        end
    end
    // drive anodes
    always_ff @( posedge clk ) begin
        if(!rst_n)
        begin
            anodes <= '1;
        end
        else
        begin
            anodes <= ~(1 << index);
        end
    end
endmodule

module TestSegDisplay #(

)(

);
    logic clk,rst_n;
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    initial begin
        rst_n = 1'b0;
        #10 rst_n = 1'b1;
    end
    logic [31:0] data=32'h12345678;
    logic [7:0] segments;
    logic [7:0] anodes;
    segDisplay #(.CLK_TO_SEGFREQ(128))
    theSegDisplay(
        clk,rst_n,
        data,
        segments,anodes
    );

endmodule