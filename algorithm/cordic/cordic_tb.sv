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