`timescale 1ns/10ps

module cordic_tb #(

)(

);
    localparam real PI = 3.1415926535;
    logic clk,rst_n,en;
    
    logic signed [31:0] step=integer'((3/180.0)*(2.0**31.0));
    logic signed [31:0] angle;
    logic signed [31:0] cosine,sine;
    initial begin
        clk=0;
        en=1;
        forever #50 clk=~clk;
    end
    initial begin
        rst_n=0;
        #100 rst_n=1;
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) angle='0;
        else if(en) angle=angle+step;
    end
    cordic #()
    theCordicInst(clk,rst_n,en,angle,cosine,sine);
    //test 45°
    /*
    initial begin
        clk=0;
        rst_n=1;
        en=1;
        repeat(62)
        begin
            #5 clk = ~clk;
            if(cosine || sine)
            begin
                $display((real'(cosine))*(2.0**(-31.0)));
                $display((real'(sine))*(2.0**(-31.0)));
                $display($sin((45.0/180.0)*3.1415926535)); 
            end
        end
    end
    Cordic #()
    theCordicInst(clk,rst_n,en,32'h20000000,cosine,sine);
    */
endmodule

module cordic #(
    parameter integer DW = 32,
    parameter real K = 0.6
)(
    input wire clk,rst_n,en,
    input wire signed [DW-1:0] angle,
    output logic signed [DW-1:0] cosine,sine
);
    wire signed [DW-1:0] atan_table[0:29];
    logic signed [DW-1:0] x_start,y_start;
    logic signed [DW-1:0] x[0:30],y[0:30],z[0:30];
    wire [1:0] domain;

    assign atan_table[00]=32'b00100000000000000000000000000000;
    assign atan_table[01]=32'b00010010111001000000010100011101;
    assign atan_table[02]=32'b00001001111110110011100001011011;
    assign atan_table[03]=32'b00000101000100010001000111010100;
    assign atan_table[04]=32'b00000010100010110000110101000011;
    assign atan_table[05]=32'b00000001010001011101011111100001;
    assign atan_table[06]=32'b00000000101000101111011000011110;
    assign atan_table[07]=32'b00000000010100010111110001010101;
    assign atan_table[08]=32'b00000000001010001011111001010011;
    assign atan_table[09]=32'b00000000000101000101111100101110;
    assign atan_table[10]=32'b00000000000010100010111110011000;
    assign atan_table[11]=32'b00000000000001010001011111001100;
    assign atan_table[12]=32'b00000000000000101000101111100110;
    assign atan_table[13]=32'b00000000000000010100010111110011;
    assign atan_table[14]=32'b00000000000000001010001011111001;
    assign atan_table[15]=32'b00000000000000000101000101111100;
    assign atan_table[16]=32'b00000000000000000010100010111110;
    assign atan_table[17]=32'b00000000000000000001010001011111;
    assign atan_table[18]=32'b00000000000000000000101000101111;
    assign atan_table[19]=32'b00000000000000000000010100010111;
    assign atan_table[20]=32'b00000000000000000000001010001011;
    assign atan_table[21]=32'b00000000000000000000000101000101;
    assign atan_table[22]=32'b00000000000000000000000010100010;
    assign atan_table[23]=32'b00000000000000000000000001010001;
    assign atan_table[24]=32'b00000000000000000000000000101000;
    assign atan_table[25]=32'b00000000000000000000000000010100;
    assign atan_table[26]=32'b00000000000000000000000000001010;
    assign atan_table[27]=32'b00000000000000000000000000000101;
    assign atan_table[28]=32'b00000000000000000000000000000010;
    assign atan_table[29]=32'b00000000000000000000000000000001;

    assign x_start= integer'(K*(2.0**(DW-1.0)));
    assign y_start='0;
    assign domain=angle[31:30];

    // convert angle to -pi/2 ~ pi/2, xy start point changes too
    always_ff @( posedge clk ) begin
        if(~rst_n)
        begin
            x[0] <= '0;
            y[0] <= '0;
            z[0] <= '0;
        end
        else if(en)
        begin
            case(domain)
                2'b00,
                2'b11:
                begin
                    x[0] <=  x_start;
                    y[0] <=  y_start;
                    z[0] <= angle;
                end
                2'b01:
                begin
                    x[0] <= -y_start;
                    y[0] <=  x_start;
                    z[0] <= {2'b00,angle[29:0]};
                end
                2'b10:
                begin
                    x[0] <=  y_start;
                    y[0] <= -x_start;
                    z[0] <= {2'b11,angle[29:0]};
                end
            endcase
        end
    end
    generate
        for(genvar i=0;i<30;i=i+1)
        begin:xyz
            wire s=z[i][31];
            wire signed [DW-1:0] x_shr=x[i]>>>i;
            wire signed [DW-1:0] y_shr=y[i]>>>i;

            always_ff @( posedge clk ) begin
                if(~rst_n)
                begin
                    x[i+1] <= '0;
                    y[i+1] <= '0;
                    z[i+1] <= '0;
                end
                else if(en)
                begin
                    x[i+1] <= s ? x[i]+y_shr : x[i]-y_shr;
                    y[i+1] <= s ? y[i]-x_shr : y[i]+x_shr;
                    z[i+1] <= s ? z[i]+atan_table[i] : z[i]-atan_table[i];
                end
            end
        end
    endgenerate
    assign cosine=x[30];
    assign sine  =y[30];
endmodule