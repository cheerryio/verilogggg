`timescale 1ns/10ps

module AD5543_tb;
    bit aclk,areset_n;
    bit clk,reset_n,co24;
    bit [15:0] data;
    bit sclk,sdi,cs_n;

    always #5 aclk=~aclk;
    initial begin
        areset_n=1'b0;
        repeat(5) @(posedge aclk);
        areset_n=1'b1;
    end
    
    logic signed [15:0] sin,cos;
    orthDds #(32,16,13) theOrthDds_1000Hz_Inst(sclk,reset_n,co24,32'd2147483,32'sd0,sin,cos);

    /*
    AD5543_32M theAD5543_32M_tb (
        aclk,areset_n,1'b1,
        data,
        clk,sdi,cs_n
    );
    */
    AD5543_96M theAD5543_96M_tb (
        aclk,areset_n,1'b1,
        data,
        clk,reset_n,co24，
        sclk,sdi,cs_n
    );
endmodule

module AD5543_96M #(
    parameter integer DW = 16
)(
    input wire aclk,areset_n,en,
    input wire [DW-1:0] data,
    output logic clk,reset_n,co24,
    (*mark_debug="true"*) output logic sclk,sdi,cs_n
);
    (*mark_debug="true"*) logic clk0;
    (*mark_debug="true"*) logic areset_n_dly;
    (*mark_debug="true"*) logic co16,co24;
    (*mark_debug="true"*) logic co16_dly;
    (*mark_debug="true"*) logic [DW-1:0] shift_data;

    always_ff @( posedge aclk ) begin
        if(!areset_n) begin
            clk<=1'b0;
        end
        else if(en) begin
            clk=~clk;
        end
    end

    always_ff @( posedge aclk ) begin
        if(!areset_n) begin
            clk0<=1'b0;
        end
        else if(en) begin
            if(co16 && clk0==1'b1) begin
                clk0<=clk0;
            end
            else if(cs_n) begin
                clk0<=1'b0;
            end
            else begin
                clk0<=~clk0;
            end
        end
    end

    always_ff @( posedge aclk ) begin
        areset_n_dly<=areset_n;
    end

    always_ff @( posedge aclk ) begin
        if(!areset_n) begin
            reset_n<=1'b0;
        end
        else if(!areset_n_dly) begin
            reset_n<=1'b0;
        end
        else begin
            reset_n<=1'b1;
        end
    end

    always_ff @( posedge clk ) begin
        if(!reset_n) begin
            cs_n<=1'b1;
        end
        else if(en) begin
            if(co24) begin
                cs_n<=1'b0;
            end
            else if(co16) begin
                cs_n<=1'b1;
            end
        end
    end

    counter #(16) theCounter16 (clk,reset_n&~co24,en,co16);
    counter #(24) theCounter24 (clk,reset_n,en,co24);

    always_ff @( posedge clk ) begin
        co16_dly<=co16;
    end

    always_ff @( posedge clk ) begin
        if(!reset_n) begin
            shift_data<='0;
        end
        else if(en) begin
            if(co24) begin
                shift_data<=data;
            end
            else if(!cs_n) begin
                shift_data<={shift_data[DW-2:0],1'b0};
            end
            else begin
                shift_data<=shift_data;
            end
        end
    end

    assign sclk=clk0;
    assign sdi=shift_data[DW-1];

endmodule