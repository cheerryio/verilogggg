`timescale 1ns/10ps

module ads127l01_tb();
    bit clk,rst_n,en;
    bit sck,dout,fsync;
    bit signed [23:0] cos;
    bit m_axis_tvalid,m_axis_tready;
    bit signed [23:0] m_axis_tdata;
    initial begin
        forever #5 clk=~clk;
    end
    initial begin
        rst_n=1'b0;
        repeat(10)@(posedge clk);
        rst_n=1'b1;
    end
    orthDds #(32,24,13) theOrthDdsInst(clk,rst_n,1'b1,32'd42949,32'd0,,cos);  ///< 10000Hz
    ads127l01_512k_master_fsync_model the_ads127l01_512k_master_fsync_model_Inst(
        clk,rst_n,1'b1,
        cos,
        sck,dout,fsync
    );
    ads127l01 #(24) the_ads127l01_Inst(
        .clk(clk),.rst_n(rst_n),.en(1'b1),
        .sck(sck),.dout(dout),.fsync(fsync),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tdata(m_axis_tdata)
    );
endmodule

module ads127l01_512k_master_fsync_model #(

)(
    input wire clk,rst_n,en,
    input wire [23:0] data,
    output logic sck,dout,fsync
);
    logic co32;
    logic [31:0] shift_data;
    logic [$clog2(16)-1:0] fsync_cnt;
    initial begin
        sck=1'b0;
        forever begin
            repeat(4) @(posedge clk);
            sck=~sck;
        end
    end
    counter #(32) the_counter32(sck,rst_n,1'b1,co32);
    assign fsync=(fsync_cnt!=1'b0);
    always_ff @( posedge sck ) begin
        if(!rst_n) begin
            fsync_cnt<='0;
        end
        else if(en) begin
            if(co32) begin
                fsync_cnt=1'b1;
            end
            else if(fsync_cnt==15) begin
                fsync_cnt=1'b0;
            end
            else if(fsync_cnt!=1'b0) begin
                fsync_cnt=fsync_cnt+1;
            end
        end
    end
    assign dout=shift_data[31];
    always_ff @( negedge sck ) begin
        if(!rst_n) begin
            shift_data<='0;
        end
        else if(en) begin
            if(co32) begin
                shift_data<={data,{8{1'b0}}};
            end
            else begin
                shift_data<={shift_data[0+:31],1'b0};
            end
        end
    end

endmodule

module ads127l01 #(
    parameter integer DW=24
)(
    input wire clk,rst_n,en,
    output logic fsmode,
    output logic format,
    output logic reset_n,
    output logic [1:0] osr,
    output logic [1:0] filter,
    output logic hr,
    output logic start,
    output logic din,
    output logic cs_n,
    output logic daisy_in,
    (*mark_debug="true"*) input wire sck,
    (*mark_debug="true"*) input wire dout,
    (*mark_debug="true"*) input wire fsync,
    (*mark_debug="true"*) output logic m_axis_tvalid,
    (*mark_debug="true"*) input  wire  m_axis_tready,
    (*mark_debug="true"*) output logic [DW-1:0] m_axis_tdata
);
    (*mark_debug="true"*) logic [31:0] shift_data;
    logic [31:0] start_cnt;
    logic sck_rising,fsync_rising;
    (*mark_debug="true"*) logic dout_r;
    assign format   = 1'b1;    // frame sync
    assign fsmode   = 1'b1;    // master
    assign reset_n  = rst_n;
    assign osr      = 2'b00;    // osr = 32
    assign filter   = 2'b01;    // wideband 2 filter
    assign hr       = 1'b1;      // hight-resolution
    assign cs_n     = 1'b0;
    assign din      = 1'b0;
    assign daisy_in = 1'b0;
    assign start=(start_cnt==32'd300);
    always @(posedge clk) begin
        if(!rst_n) begin
            start_cnt <= 1'b0;
        end
        else if(en) begin
            if(start_cnt<32'd300) begin
                start_cnt <= start_cnt + 1'b1;
            end
        end
    end
    Rising2En #(1) fsync2en(clk,fsync,fsync_rising,),sck2en(clk,sck,sck_rising,);
    always_ff @( posedge clk ) begin
        dout_r<=dout;
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            shift_data<='0;
        end
        else begin
            if(sck_rising) begin
                shift_data<={shift_data[0+:31],dout_r}; 
            end
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            m_axis_tdata<='0;
        end
        else begin
            if(fsync_rising) begin
                m_axis_tdata<=shift_data[8+:24];
            end
        end
    end
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            m_axis_tvalid<=1'b0;
        end
        else begin
            if(fsync_rising) begin
                m_axis_tvalid<=1'b1&en;
            end
            else begin
                m_axis_tvalid<=1'b0;
            end
        end
    end
endmodule

module Rising2En #( parameter SYNC_STG = 1 )(
    input wire clk, in,
    output logic en, out
);
    logic [SYNC_STG : 0] dly;
    always @(posedge clk) begin
        dly <= {dly[SYNC_STG - 1 : 0], in};
    end
    assign en = (SYNC_STG ? dly[SYNC_STG -: 2] : {dly, in}) == 2'b01;
    assign out = dly[SYNC_STG];
endmodule