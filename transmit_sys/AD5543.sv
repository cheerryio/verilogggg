`timescale 1ns/10ps

module AD5543_stream_tb;
    bit fclk,freset_n;
    bit aclk,aresetn,co24;
    bit [15:0] cos;
    bit sclk,sdi,cs_n;

    always #5 fclk=~fclk;
    initial begin
        freset_n=1'b0;
        repeat(5) @(posedge fclk);
        freset_n=1'b1;
    end

    orthDds #(32,16,13) theOrthDds_1000Hz_Inst(fclk,freset_n,1'b1,32'd85899,32'sd0,,cos);

    AD5543_96M_stream theAD5543_96M_stream_tb (
        aclk,aresetn,
        fclk,freset_n,
        1'b1,1'b1,,
        cos,
        aclk,aresetn,
        sclk,sdi,cs_n
    );

    bit signed [15:0] data;
    AD5543_collect_sim #(16) theAD5543_collect_sim_Inst(
        sclk,sdi,cs_n,
        data
    );
endmodule

module AD5543_collect_sim #(
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

module AD5543_96M_stream #(
    parameter integer DW = 16
)(
    input wire s_axis_aclk,s_axis_aresetn,
    input wire fclk,freset_n,
    input wire en,
    input wire s_axis_tvalid,
    output logic s_axis_tready,
    input wire [DW-1:0] s_axis_tdata,
    output logic aclk_b,aresetn_b,
    (*mark_debug="true"*) output logic sclk,sdi,cs_n
);
    (*mark_debug="true"*) logic clk,clk0;
    logic reset_n,freset_n_dly;
    logic co16,co24;
    logic co16_dly;
    //logic signed [DW-1:0] s_axis_tdata;
    logic [DW-1:0] shift_data;
    //orthDds #(32,16,13) theOrthDds_1000Hz_Inst(clk,reset_n,1'b1,32'd85899,32'sd0,s_axis_tdata,);

    always_ff @( posedge fclk ) begin
        if(!freset_n) begin
            clk<=1'b0;
        end
        else if(en) begin
            clk=~clk;
        end
    end

    always_ff @( posedge fclk ) begin
        if(!freset_n) begin
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

    always_ff @( posedge fclk ) begin
        freset_n_dly<=freset_n;
    end

    always_ff @( posedge fclk ) begin
        if(!freset_n) begin
            reset_n<=1'b0;
        end
        else if(!freset_n_dly) begin
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
                shift_data<=s_axis_tdata;
            end
            else if(!cs_n) begin
                shift_data<={shift_data[DW-2:0],1'b0};
            end
            else begin
                shift_data<=shift_data;
            end
        end
    end

    assign aclk_b=clk;
    assign aresetn_b=reset_n;
    assign s_axis_tready=co24;
    assign sclk=clk0;
    assign sdi=shift_data[DW-1];
endmodule

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
    orthDds #(32,16,13) theOrthDds_1000Hz_Inst(clk,reset_n,1'b1,32'd85899,32'sd0,sin,cos);

    AD5543_96M theAD5543_96M_tb (
        aclk,areset_n,1'b1,
        //cos,
        sclk,sdi,cs_n
    );
endmodule

module AD5543_96M #(
    parameter integer DW = 16
)(
    input wire aclk,areset_n,en,
    //input wire [DW-1:0] data,
    (*mark_debug="true"*) output logic sclk,sdi,cs_n
);
    (*mark_debug="true"*) logic clk,clk0;
    (*mark_debug="true"*) logic reset_n,areset_n_dly;
    (*mark_debug="true"*) logic co16,co24;
    (*mark_debug="true"*) logic co16_dly;
    (*mark_debug="true"*) logic signed [DW-1:0] data;
    (*mark_debug="true"*) logic [DW-1:0] shift_data;
    orthDds #(32,16,13) theOrthDds_1000Hz_Inst(clk,reset_n,1'b1,32'd85899,32'sd0,data,);

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