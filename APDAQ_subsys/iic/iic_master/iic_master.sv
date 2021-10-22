`timescale 1ns/10ps

module iic_master #(
    parameter int DIV=500
)(
    input wire clk,rst_n,en,
    input wire start,
    input wire [6:0] dev_addr,
    input wire [7:0] reg_addr,
    input wire wr,
    input wire [7:0] wdata,
    (*mark_debug="true"*) output logic [7:0] rdata,
    (*mark_debug="true"*) output logic done,
    
    (*mark_debug="true"*) input wire scl_i,
    (*mark_debug="true"*) output logic scl_o,
    (*mark_debug="true"*) output logic scl_t,
    (*mark_debug="true"*) input wire sda_i,
    (*mark_debug="true"*) output logic sda_o,
    (*mark_debug="true"*) output logic sda_t
);
    parameter int IDLE=4'd0;
    parameter int LOAD_WRITE_DEV_ADDR=4'd1;
    parameter int LOAD_REG_ADDR=4'd2;
    parameter int LOAD_WDATA=4'd3;
    parameter int SEND_FIRST_START=4'd4;
    parameter int SEND_BYTE=4'd5;
    parameter int RECEIVE_ACK=4'd6;
    parameter int CHECK_ACK=4'd7;
    parameter int LOAD_READ_DEV_ADDR=4'd8;
    parameter int SEND_SECOND_START=4'd9;
    parameter int READ_BYTE=4'd10;
    parameter int SEND_UNACK=4'd11;
    parameter int PREPARE_STOP=4'd12;
    parameter int SEND_STOP=4'd13;
    parameter int FINAL=4'd14;
    (*mark_debug="true"*) logic high_mid,low_mid,fall;
    (*mark_debug="true"*) logic [3:0] state,state_jump;
    (*mark_debug="true"*) logic [3:0] bit_cnt;
    (*mark_debug="true"*) logic [7:0] load_data;
    (*mark_debug="true"*) logic ack;
    clock_divider #(DIV) the_clock_divider_Inst(
        clk,rst_n,scl_t,
        scl_o,
        high_mid,low_mid,fall
    );
    always_ff @( posedge clk ) begin
        if(!rst_n) begin
            scl_t<=1'b0;
            sda_t<=1'b1;
            sda_o<=1'b1;
            bit_cnt<='0;
            ack<=1'b0;
            done<=1'b0;
            state<=IDLE;
            state_jump<=IDLE;
        end
        else if(en) begin
            case(state)
            IDLE:begin
                scl_t<=1'b0;
                sda_t<=1'b1;
                sda_o<=1'b1;
                bit_cnt<='0;
                ack<=1'b0;
                done<=1'b0;
                state_jump<=IDLE;
                if(start) begin
                    state<=LOAD_WRITE_DEV_ADDR;
                end
            end
            LOAD_WRITE_DEV_ADDR:begin
                load_data<={dev_addr,1'b0};
                state<=SEND_FIRST_START;
                state_jump<=LOAD_REG_ADDR;
            end
            LOAD_REG_ADDR:begin
                load_data<={reg_addr};
                state<=SEND_BYTE;
                if(wr) begin
                    state_jump<=LOAD_WDATA; 
                end
                else begin
                    state_jump<=SEND_SECOND_START;
                end
            end
            LOAD_WDATA:begin
                load_data<={wdata};
                state<=SEND_BYTE;
                state_jump<=PREPARE_STOP;
            end
            SEND_FIRST_START:begin
                scl_t<=1'b1;
                sda_t<=1'b1;
                if(high_mid) begin
                    sda_o<=1'b0;
                    state<=SEND_BYTE;
                end
                else begin
                    state<=SEND_FIRST_START;
                end
            end
            SEND_BYTE:begin
                scl_t<=1'b1;
                sda_t<=1'b1;
                if(low_mid) begin
                    if(bit_cnt<4'd8) begin
                        bit_cnt<=bit_cnt+1'b1;
                        sda_o<=load_data[7-bit_cnt];
                        state<=SEND_BYTE;
                    end
                    else begin
                        bit_cnt<='0;
                        state<=RECEIVE_ACK;
                    end
                end
                else begin
                    state<=SEND_BYTE;
                end
            end
            RECEIVE_ACK:begin
                scl_t<=1'b1;
                sda_t<=1'b0;
                if(high_mid) begin
                    ack<=sda_i;
                    state<=CHECK_ACK;
                end
                else begin
                    state<=RECEIVE_ACK;
                end
            end
            CHECK_ACK:begin
                scl_t<=1'b1;
                if(ack==1'b0) begin
                    if(fall) begin
                        state<=state_jump;
                    end
                end
                else begin
                    state<=IDLE;
                end
            end
            LOAD_READ_DEV_ADDR:begin
                load_data<={dev_addr,1'b1};
                state<=SEND_BYTE;
                state_jump<=READ_BYTE;
            end
            SEND_SECOND_START:begin
                scl_t<=1'b1;
                sda_t<=1'b1;
                sda_o<=1'b1;
                if(high_mid) begin
                    sda_o<=1'b0;
                    state<=LOAD_READ_DEV_ADDR;
                end
                else begin
                    state<=SEND_SECOND_START;
                end
            end
            READ_BYTE:begin
                scl_t<=1'b1;
                sda_t<=1'b0;
                if(high_mid) begin
                    if(bit_cnt<4'd7) begin
                        rdata<={rdata[0+:7],sda_i};
                        bit_cnt<=bit_cnt+1'b1;
                        state<=READ_BYTE;
                    end
                    else begin
                        rdata<={rdata[0+:7],sda_i};
                        bit_cnt<='0;
                        state<=SEND_UNACK;
                    end
                end
                else begin
                    state<=READ_BYTE;
                end
            end
            SEND_UNACK:begin
                scl_t<=1'b1;
                sda_t<=1'b0;
                if(low_mid) begin
                    sda_t<=1'b1;
                    sda_o<=1'b1;
                    state<=PREPARE_STOP;
                end
                else begin
                    state<=SEND_UNACK;
                end
            end
            PREPARE_STOP:begin
                scl_t<=1'b1;
                if(low_mid) begin
                    sda_t<=1'b1;
                    sda_o<=1'b0;
                    state<=SEND_STOP;
                end
                else begin
                    state<=PREPARE_STOP;
                end
            end
            SEND_STOP:begin
                scl_t<=1'b1;
                sda_t<=1'b1;
                if(high_mid) begin
                    sda_o<=1'b1;
                    state<=FINAL;
                end
                else begin
                    state<=SEND_STOP;
                end
            end
            FINAL:begin
                scl_t<=1'b0;
                sda_t<=1'b1;
                sda_o<=1'b1;
                done<=1'b1;
                state<=IDLE;
            end
            default:begin
                state<=IDLE;
            end
            endcase
        end
    end
endmodule