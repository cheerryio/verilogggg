`timescale 1ns/10ps

module ads127l01_tb();
    bit clk,rst_n,en;
    bit sck,dout,fsync;
    bit signed [23:0] cos;
    bit m_axis_tvalid,m_axis_tready;
    bit signed [23:0] m_axis_tdata;
    bit high;
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
        .m_axis_tdata(m_axis_tdata),
        .high(high)
    );
endmodule