// vi:set ft=verilog ts=4 sw=4 expandtab ai si:
// loywong@hust.edu.cn 20140902

module iic_master_engine
#(
    parameter real CLK_FREQ = 100e6,
    // max time: 1023 / CLK_FREQ
    // T_SSU: Setup time for repeat START
    // T_SSU + T_PH = MIN BUS IDLE
    parameter real T_SSU  = 0.6e-6,
    parameter real T_SH   = 0.6e-6,
    // T_DSU + T_SCLH + T_DH = 1 / (BUS FREQ)
    // !!! Be sure T_DSU is the maximum one !!!
    parameter real T_DSU  = 1.3e-6,
    parameter real T_SCLH = 0.9e-6,
    parameter real T_DH   = 0.3e-6,
    parameter real T_PSU  = 0.6e-6,
    parameter real T_PH   = 0.7e-6
)(
    input wire clk,
    input wire arst,
    
    input wire [9:0] trans_fifo_q,
    output wire trans_fifo_rd,
    input wire trans_fifo_empty,
    
    output wire [8:0] recv_fifo_data,
    output wire recv_fifo_wr,
    
//    inout scl,
//    inout sda
    input wire scl_i,
    output wire scl_o,
    output wire scl_t,
    
    input wire sda_i,
    output wire sda_o,
    output wire sda_t
);

    (* mark_debug = "true" *) wire [1:0] iic_bit;
    (* mark_debug = "true" *) wire bit_go;
    (* mark_debug = "true" *) wire bit_idle;
//    wire scl_out;
//    wire sda_out;
    
//    assign scl = (scl_out? 1'bz : scl_out);
//    assign sda = (sda_out? 1'bz : sda_out);

    assign scl_t = scl_o;
    assign sda_t = sda_o;
    
    iic_master_byte_trans byte_trans_inst
    (
        .clk(clk),
        .arst(arst),
        .fifo_q(trans_fifo_q),
        .fifo_rd(trans_fifo_rd),
        .fifo_empty(trans_fifo_empty),
        .iic_bit(iic_bit),
        .bit_go(bit_go),
        .bit_idle(bit_idle),
        .wr_9bit_end(recv_fifo_wr)
    );
    
    iic_master_bit_trans
    #(
        .CLK_FREQ(CLK_FREQ),
        .T_SSU(T_SSU),
        .T_SH(T_SH),
        .T_DSU(T_DSU),
        .T_SCLH(T_SCLH),
        .T_DH(T_DH),
        .T_PSU(T_PSU),
        .T_PH(T_PH)
    )
    bit_trans_inst
    (
        .clk(clk),
        .arst(arst),
        .iic_bit(iic_bit),
        .go(bit_go),
        .idle(bit_idle),
        .scl_out(scl_o),
        .sda_out(sda_o),
        .scl(scl_i)
    );
    
    iic_master_receiver_shift recv_shift_inst
    (
        .clk(clk),
        .scl(scl_i),
        .sda(sda_i),
        .shift(recv_fifo_data)
    );
    
endmodule

module iic_master_bit_trans
#(
    parameter real CLK_FREQ = 100e6,
    parameter real T_SSU  = 0.6e-6,
    parameter real T_SH   = 0.6e-6,
    parameter real T_DSU  = 1.3e-6,
    parameter real T_SCLH = 0.9e-6,
    parameter real T_DH   = 0.3e-6,
    parameter real T_PSU  = 0.6e-6,
    parameter real T_PH   = 0.7e-6
)(
    input wire clk,
    input wire arst,
    // iic_bit: 00: clr dat; 01: rls dat; 10: start; 11: stop
    input wire [1:0] iic_bit,
    input wire go,
    output wire idle,
    output reg scl_out,
    input wire scl,
    output reg sda_out
);
   	function integer CLOG2(input integer val);
		for(CLOG2 = 0; val > 1; CLOG2 = CLOG2 + 1)
			val = val >> 1;
    endfunction
    
    wire [9:0] t_ssu_limit  = (CLK_FREQ * T_SSU);
    wire [9:0] t_sh_limit   = (CLK_FREQ * T_SH);
    wire [9:0] t_dsu_limit  = (CLK_FREQ * T_DSU);
    wire [9:0] t_sclh_limit = (CLK_FREQ * T_SCLH);
    wire [9:0] t_dh_limit   = (CLK_FREQ * T_DH);
    wire [9:0] t_psu_limit  = (CLK_FREQ * T_PSU);
    wire [9:0] t_ph_limit   = (CLK_FREQ * T_PH);
    reg [CLOG2(CLK_FREQ * T_DSU  + 0.5 - 1):0] t_cnt; initial t_cnt = 1'b0;
   
// sda: ^^^^^\___________X=================...X_____________/^^^^
// scl: ^^^^^^^^^^\____________/^^^^^^\____...________/^^^^^^^^^^
//       SSU   SH   S_DH   DSU   SCLH   DH      P_DSU   PSU   PH
    localparam S_IDLE = 4'd0;
    localparam S_SSU  = 4'd1;
    localparam S_SH   = 4'd2;
    localparam S_SDH  = 4'd3;
    localparam S_DSU  = 4'd4;
    localparam S_SCLH = 4'd5;
    localparam S_DH   = 4'd6;
    localparam S_PDSU = 4'd7;
    localparam S_PSU  = 4'd8;
    localparam S_PH   = 4'd9;
    
    reg [3:0] state, next_state; initial {state, next_state} = {S_IDLE, S_IDLE};
    
    assign idle = (state == S_IDLE) | (next_state == S_IDLE);

    always@(posedge clk or posedge arst)
    begin
        if(arst) state <= S_IDLE;
        else state <= next_state;
    end

    always@(*)
    begin
        next_state = state;
        case(state)
        S_IDLE:
            if(go)
            begin
                if(iic_bit == 2'b10) next_state = S_SSU;
                else if(iic_bit == 2'b11) next_state = S_PDSU;
                else next_state = S_DSU;
            end
        S_SSU:
            if(t_cnt == t_ssu_limit  - 4'h1) next_state = S_SH;
        S_SH:
            if(t_cnt == t_sh_limit   - 4'h1) next_state = S_SDH;
        S_SDH:
            if(t_cnt == t_dh_limit   - 4'h5) next_state = S_IDLE;
        S_PDSU:
            if(t_cnt == t_dsu_limit  - 4'h1) next_state = S_PSU;
        S_PSU:
            if(t_cnt == t_psu_limit  - 4'h1) next_state = S_PH;
        S_PH:
            if(t_cnt == t_ph_limit   - 4'h5) next_state = S_IDLE;
        S_DSU:
            if(t_cnt == t_dsu_limit  - 4'h1) next_state = S_SCLH;
        S_SCLH:
            if(t_cnt == t_sclh_limit - 4'h1) next_state = S_DH;
        S_DH:
            if(t_cnt == t_dh_limit   - 4'h2) next_state = S_IDLE;
        default:
            next_state = S_IDLE;
        endcase
    end

    always@(posedge clk or posedge arst)
    begin
        if(arst) t_cnt <= 1'b0;
        else
        begin
            if((state == S_IDLE) || (next_state != state))
                t_cnt <= 1'b0;
            else if(scl == scl_out) // clk sync
                t_cnt <= t_cnt + 1'b1;
        end
    end

    always@(posedge clk or posedge arst)
    begin
        if(arst)
        begin
            scl_out <= 1'b1;
            sda_out <= 1'b1;
        end
        else
        begin
            case(next_state)
            S_SSU:
            begin
                scl_out <= 1'b1;
                sda_out <= 1'b1;
            end
            S_SH:
            begin
                scl_out <= 1'b1;
                sda_out <= 1'b0;
            end
            S_SDH:
            begin
                scl_out <= 1'b0;
                sda_out <= 1'b0;
            end
            S_PDSU:
            begin
                scl_out <= 1'b0;
                sda_out <= 1'b0;
            end
            S_PSU:
            begin
                scl_out <= 1'b1;
                sda_out <= 1'b0;
            end
            S_PH:
            begin
                scl_out <= 1'b1;
                sda_out <= 1'b1;
            end
            S_DSU:
            begin
                scl_out <= 1'b0;
                sda_out <= iic_bit[0];
            end
            S_SCLH:
            begin
                scl_out <= 1'b1;
                sda_out <= iic_bit[0];
            end
            S_DH:
            begin
                scl_out <= 1'b0;
                sda_out <= iic_bit[0];
            end
            endcase
        end
    end

endmodule

// byte             means 
// 0_XXXXXXXX_1     write byte & read ack
// 0_XXXXXXXX_0     write byte & write ack
// 0_11111111_0     read byte & write ack
// 0_11111111_1     read byte & read ack
// 1_0XXXXXXX_X     start
// 1_1XXXXXXX_X     stop
module iic_master_byte_trans
(
    input wire clk,
    input wire arst,
    input wire [9:0] fifo_q,
    output wire fifo_rd,
    input wire fifo_empty,
    output reg [1:0] iic_bit,
    output reg bit_go,
    input wire bit_idle,
    output wire wr_9bit_end
);
    localparam S_IDLE      = 3'd0;
    localparam S_RDFIFO    = 3'd1;
    localparam S_CASE      = 3'd2;
    localparam S_1BIT_WR   = 3'd3;
    localparam S_1BIT_WAIT = 3'd4;
    localparam S_9BIT_WR   = 3'd5;
    localparam S_9BIT_WAIT = 3'd6;
    
    reg [8:0] wrdata;
    initial wrdata = 9'b0;
    reg [3:0] wrdata_bit;
    initial wrdata_bit = 4'b0;

    reg [2:0] state, next_state;
    initial
    begin
        state = S_IDLE;
        next_state = S_IDLE;
    end

    always@(posedge clk or posedge arst)
    begin
        if(arst) state <= S_IDLE;
        else state <= next_state;
    end

    always@(*)
    begin
        next_state = state;
        case(state)
        S_IDLE:
            if(~fifo_empty) next_state = S_RDFIFO;
        S_RDFIFO:
            next_state = S_CASE;
        S_CASE:
            if(fifo_q[9])
                next_state = S_1BIT_WR;
            else
                next_state = S_9BIT_WR;
        S_1BIT_WR:
            next_state = S_1BIT_WAIT;
        S_1BIT_WAIT:
            if(bit_idle)
                next_state = S_IDLE;
        S_9BIT_WR:
            next_state = S_9BIT_WAIT;
        S_9BIT_WAIT:
            if(bit_idle)
            begin
                if(wrdata_bit == 4'h8)
                    next_state = S_IDLE;
                else
                    next_state = S_9BIT_WR;
            end
        default:
            next_state = S_IDLE;
        endcase
    end
    
    assign fifo_rd = (state == S_RDFIFO);
    
    always@(posedge clk)
    begin
        if(state == S_CASE)
        begin
            wrdata <= fifo_q[8:0];
            wrdata_bit <= 4'b0;
        end
        else if(state == S_9BIT_WAIT && next_state == S_9BIT_WR)
        begin
            wrdata <= {wrdata[7:0], 1'b1};
            wrdata_bit <= wrdata_bit + 1'b1;
        end
    end
    
    always@(*)
    begin
        if(state == S_1BIT_WR || state == S_9BIT_WR)
            bit_go = 1'b1;
        else
            bit_go = 1'b0;
    end

    always@(*)
    begin
        if(state == S_1BIT_WR || state == S_1BIT_WAIT)
            iic_bit = {1'b1, wrdata[8]};
        else/* if(state == S_9BIT_WR || state == S_9BIT_WAIT)*/
            iic_bit = {1'b0, wrdata[8]};
    end
	 
	 assign wr_9bit_end = (state == S_9BIT_WAIT && next_state == S_IDLE);

endmodule

module iic_master_receiver_shift
(
    input wire clk,
    input wire scl,
    input wire sda,
    output reg [8:0] shift
);
    initial shift = 9'b0;
    reg scl_last0, scl_last1;
    initial scl_last0 = 1'b1;
    initial scl_last1 = 1'b1;
    
    always@(posedge clk) scl_last0 <= scl;
    always@(posedge clk) scl_last1 <= scl_last0;
    wire scl_th = (scl_last0 & ~scl_last1);
    
    always@(posedge clk)
    begin
        if(scl_th) shift <= {shift[7:0], sda};
    end
    
endmodule
