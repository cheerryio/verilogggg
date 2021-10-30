`timescale 1ns/10ps

module ads127l01 #(
    parameter int DW=24,
    parameter int LAST=10240
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
    input wire sck,
    input wire dout,
    input wire fsync,
    output logic m_axis_tvalid,
    input wire  m_axis_tready,
    output logic m_axis_tlast,
    output logic [DW-1:0] m_axis_tdata,

    output logic high
);
    logic [31:0] shift_data;
    logic [31:0] start_cnt;
    logic sck_rising,fsync_rising;
    logic dout_r;
    wire osh=m_axis_tvalid&m_axis_tready;
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
    counter #(LAST) the_last_counter(clk,rst_n,osh,m_axis_tlast);
    assign high=~(m_axis_tdata[DW-1]^m_axis_tdata[DW-2]);
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