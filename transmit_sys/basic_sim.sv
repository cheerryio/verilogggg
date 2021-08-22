`timescale 1ns/10ps

interface basic_sim_if #(
    parameter integer DW = 16
);
    logic aclk,aresetn;
    logic fclk0,fclk1;
    logic en;
    logic sclk,sdi,cs_n;
    logic signed [DW-1:0] recv_data;
endinterface

module basic_sim_tb;
    localparam integer BRAM_BASE_ADDR = 32'h4000_0000;
    localparam integer DMA_BASE_ADDR  = 32'h4040_0000;
    localparam integer DMA_IRQ_ID = 4'b0000;
    localparam integer FIFO_IRQ_ID = 4'b0001;
    localparam integer SINE_LEN = 200;

    localparam real PI=3.1415926535897932;
    
    basic_sim_if b_if();

    wire temp_aclk,temp_aresetn;
    assign temp_aclk=b_if.aclk;
    assign temp_aresetn=b_if.aresetn;
    assign b_if.fclk0=basic_sim_tb.UUT.basic_i.processing_system7_0_FCLK_CLK0;
    assign b_if.fclk1=basic_sim_tb.UUT.basic_i.processing_system7_0_FCLK_CLK1;

    initial begin
        b_if.aclk=1'b0;
        forever #5 b_if.aclk=~b_if.aclk;
    end

    event config_finish;
    initial begin
        automatic bit resp;
        automatic bit [63:0] data;
        automatic bit [63:0] read_data;
        automatic bit signed [15:0] sine[SINE_LEN];
        
        b_if.aresetn = 1'b0;
        repeat(20)@(posedge b_if.aclk);        
        b_if.aresetn = 1'b1;
        @(posedge b_if.aclk);

        repeat(5) @(posedge b_if.aclk);
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.set_stop_on_error(1'b1);
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.set_debug_level_info(1'b0);
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.fpga_soft_reset(32'h0);
        $display("PL reset complete...");

        for(int i=0;i<SINE_LEN;i++) begin
            sine[i]=$sin(2.0*PI*i/SINE_LEN)*(2.0**15-1.0);
        end

        for(int i=0;i<SINE_LEN;) begin
            repeat(100)@(posedge b_if.aclk);
            data={sine[i+3],sine[i+2],sine[i+1],sine[i]};
            basic_sim_tb.UUT.basic_i.processing_system7_0.inst.write_data(BRAM_BASE_ADDR+i*2,8,data,resp);
            basic_sim_tb.UUT.basic_i.processing_system7_0.inst.read_data(BRAM_BASE_ADDR+i*2,8,read_data,resp);
            $display("read write data:%x",read_data);
            i=i+4;
        end

        ->config_finish;
    end

    initial begin
        automatic bit [15:0] irq_status;
        automatic bit [31:0] offset_addr;
        automatic bit [31:0] data;
        automatic bit resp;

        @(config_finish);
        forever begin
            basic_sim_tb.UUT.basic_i.processing_system7_0.inst.wait_interrupt(FIFO_IRQ_ID,irq_status);
            dma_transfer(BRAM_BASE_ADDR,SINE_LEN*2);
            basic_sim_tb.UUT.basic_i.processing_system7_0.inst.wait_interrupt(DMA_IRQ_ID,irq_status);
            repeat(10)@(posedge b_if.fclk0);
            offset_addr=32'h4;
            data=32'b0000_0000_0000_0000_0001_0000_0000_0000;
            basic_sim_tb.UUT.basic_i.processing_system7_0.inst.write_data(DMA_BASE_ADDR+offset_addr,4,data,resp);
        end
    end

    AD5543_collect_sim #(16) AD5543_collect_sim_tb_Inst(
        b_if.sclk,
        b_if.sdi,
        b_if.cs_n,
        b_if.recv_data
    );

    task dma_transfer(bit [31:0] src,bit [31:0] length);
        automatic bit [31:0] read_data;
        automatic bit [31:0] offset_addr;
        automatic bit [31:0] data;
        automatic bit resp;

        $display("try start dma transaction");
        $display("configure dma RD and INTR resp:%d",resp);
        offset_addr=32'h0;
        data=32'b0000_0000_0000_0000_0001_0000_0000_0001;
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.read_data(DMA_BASE_ADDR+offset_addr,4,read_data,resp);
        $display("before write MM2S_DMACR:%b",read_data);
        data=read_data|data;
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.write_data(DMA_BASE_ADDR+offset_addr,4,data,resp);
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.read_data(DMA_BASE_ADDR+offset_addr,4,read_data,resp);
        $display("after  write MM2S_DMACR:%b",read_data);
        
        offset_addr=32'h4;
        data=~(32'h1);
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.read_data(DMA_BASE_ADDR+offset_addr,4,read_data,resp);
        $display("before write MM2S_DMASR:%b",read_data);
        data=read_data&data;
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.write_data(DMA_BASE_ADDR+offset_addr,4,data,resp);

        // set source address
        $display("set dma source address");
        offset_addr=32'h18;
        data=src;
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.write_data(DMA_BASE_ADDR+offset_addr,4,data,resp);

        // set read length
        $display("set dma read length");
        offset_addr=32'h28;
        data=length;
        basic_sim_tb.UUT.basic_i.processing_system7_0.inst.write_data(DMA_BASE_ADDR+offset_addr,4,data,resp);
    endtask



    basic_wrapper UUT(
        .DDR_addr(),
        .DDR_ba(),
        .DDR_cas_n(),
        .DDR_ck_n(),
        .DDR_ck_p(),
        .DDR_cke(),
        .DDR_cs_n(),
        .DDR_dm(),
        .DDR_dq(),
        .DDR_dqs_n(),
        .DDR_dqs_p(),
        .DDR_odt(),
        .DDR_ras_n(),
        .DDR_reset_n(),
        .DDR_we_n(),
        .FIXED_IO_ddr_vrn(),
        .FIXED_IO_ddr_vrp(),
        .FIXED_IO_mio(),
        .FIXED_IO_ps_clk(temp_aclk),
        .FIXED_IO_ps_porb(temp_aresetn),
        .FIXED_IO_ps_srstb(temp_aresetn),
        .cs_n(b_if.cs_n),
        .sclk(b_if.sclk),
        .sdi(b_if.sdi)
        );
endmodule