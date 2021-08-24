`timescale 1ns/10ps
module collection_sys_final_sim();
    localparam integer FIFO_IRQ_THRESHOLD = 32'd512;
    localparam integer FIFO_BASE_ADDR = 32'h43c0_0000;
    localparam integer FIFO_IRQ_ID = 4'b0000;
    localparam integer ROUND = 50;

    bit aclk,aresetn;
    wire temp_aclk,temp_aresetn;

    bit sclk,drdy,dout;
    bit sclk_clk_p,sclk_clk_n;
    bit drdy_clk_p,drdy_clk_n;
    bit dout_clk_p,dout_clk_n;

    bit signed [23:0] goden_data[$]={24'd0};
    bit signed [23:0] recev_data[$];
    bit signed [23:0] data_trans,data_recv;

    bit [31:0] read_data;
    bit [31:0] addr,offset_addr;
    bit [31:0] data;

    always #5 aclk=~aclk;
    assign temp_aclk=aclk;
    assign temp_aresetn=aresetn;

    event config_finish;
    
    initial begin
        automatic bit resp;
        automatic bit [15:0] irq_status;

        aresetn = 1'b0;
        repeat(20)@(posedge aclk);        
        aresetn = 1'b1;
        @(posedge aclk);

        repeat(5) @(posedge aclk);
        collection_sys_final_sim.UUT.basic_i.processing_system7_0.inst.set_stop_on_error(1'b1);
        collection_sys_final_sim.UUT.basic_i.processing_system7_0.inst.set_debug_level_info(1'b0);
        collection_sys_final_sim.UUT.basic_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
        collection_sys_final_sim.UUT.basic_i.processing_system7_0.inst.fpga_soft_reset(32'h0);
        $display("PL reset complete...");

        // configure ip axi4l_fifo
        offset_addr=4*8;
        data=2'b01;
        collection_sys_final_sim.UUT.basic_i.processing_system7_0.inst.write_data(FIFO_BASE_ADDR+offset_addr,4,data,resp);
        offset_addr=4*3;
        data=FIFO_IRQ_THRESHOLD;
        collection_sys_final_sim.UUT.basic_i.processing_system7_0.inst.write_data(FIFO_BASE_ADDR+offset_addr,4,data,resp);
        $display("config finish...");
        ->config_finish;
    end

    /*
     * simulate 
     */
    initial begin
        @(config_finish);
        fork
            begin
                automatic bit [15:0] irq_status;
                automatic bit [31:0] read_data;
                automatic bit resp;
                for(int i=0;i<ROUND;i++) begin
                    collection_sys_final_sim.UUT.basic_i.processing_system7_0.inst.wait_interrupt(FIFO_IRQ_ID,irq_status);
                    for(int i=0;i<FIFO_IRQ_THRESHOLD;i++) begin
                        collection_sys_final_sim.UUT.basic_i.processing_system7_0.inst.read_data(FIFO_BASE_ADDR,4,read_data,resp);
                        recev_data.push_back(read_data);
                    end
                    $display("finish collecting data, ROUND %d...",i);
                end
            end
        join
        // wait for data check finish
        repeat(5)@(posedge aclk);
        $finish;
    end
    initial begin
        automatic bit signed [23:0] a,b;
        forever begin
            wait(goden_data.size()!=0 && recev_data.size()!=0);
            a=goden_data.pop_front();
            b=recev_data.pop_front();
            $display("a=%x, b=%x",a,b);
        end
    end

    initial begin
        forever begin
            @(negedge drdy);
            data_trans=$random();
            goden_data.push_back(data_trans);
        end
    end

    ADS1675_32M_SOURCE_2M_SAMPLE_RATE_MODEL theADS1675_32M_SOURCE_2M_SAMPLE_RATE_MODEL_Inst(
        aclk,aresetn,1'b1,
        sclk,drdy,dout,
        data_trans
    );
    OBUFDS sclk_obufds_inst (
        .I(sclk),.O(sclk_clk_p),.OB(sclk_clk_n)
    );
    OBUFDS drdy_obufds_inst (
        .I(drdy),.O(drdy_clk_p),.OB(drdy_clk_n)
    );
    OBUFDS dout_obufds_inst (
        .I(dout),.O(dout_clk_p),.OB(dout_clk_n)
    );
    basic_wrapper UUT
    (.DDR_addr(),
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
    .clk_sel(),
    .cs_n(),
    .dout_clk_n(dout_clk_n),
    .dout_clk_p(dout_clk_p),
    .dr0(),
    .dr1(),
    .dr2(),
    .fpath(),
    .ll_cfg(),
    .lvds(),
    .pown(),
    .drdy_clk_n(drdy_clk_n),
    .drdy_clk_p(drdy_clk_p),
    .sclk_clk_n(sclk_clk_n),
    .sclk_clk_p(sclk_clk_p),
    .start());
endmodule