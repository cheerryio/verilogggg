`timescale 1ns/10ps

`define ZYNQ DNCDAQ_subsys_sim.DUT.DNCDAQ_subsys_i.processing_system7_0.inst
`define WRAPPER DNCDAQ_subsys_wrapper
module DNCDAQ_subsys_sim();
    localparam integer FIFO_IRQ_THRESHOLD = 32'd300;
    localparam integer FIFO_BASE_ADDR = 32'h43c0_0000;
    localparam integer FIFO_IRQ_ID = 4'b0000;
    localparam integer ADC_ENABLE_GPIO_BASEADDR = 32'h4120_0000;
    localparam integer ROUND = 50;

    bit aclk,aresetn;
    wire temp_aclk,temp_aresetn;

    bit sclk,drdy;
    bit sclk_p,sclk_n;
    bit drdy_p,drdy_n;
    bit dout_p,dout_n;

    bit signed [31:0] goden_data[$]={};
    bit signed [31:0] recev_data[$];
    bit signed [23:0] data_trans;
    bit signed [31:0] data_recv;

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
        `ZYNQ.set_stop_on_error(1'b1);
        `ZYNQ.set_debug_level_info(1'b0);
        `ZYNQ.fpga_soft_reset(32'h1);
        `ZYNQ.fpga_soft_reset(32'h0);
        $display("PL reset complete...");

        // configure ip axi4l_fifo
        offset_addr=4*8;
        data=2'b01;
        `ZYNQ.write_data(FIFO_BASE_ADDR+offset_addr,4,data,resp);
        offset_addr=4*3;
        data=FIFO_IRQ_THRESHOLD;
        `ZYNQ.write_data(FIFO_BASE_ADDR+offset_addr,4,data,resp);

        $display("config finish...");
        ->config_finish;
    end

    /*
     * simulate 
     */
    initial begin
        automatic bit resp;
        @(config_finish);
        fork
            begin
                automatic bit [15:0] irq_status;
                automatic bit [31:0] read_data;
                for(int i=0;i<ROUND;i++) begin
                    `ZYNQ.wait_interrupt(FIFO_IRQ_ID,irq_status);
                    for(int i=0;i<FIFO_IRQ_THRESHOLD;i++) begin
                        `ZYNQ.read_data(FIFO_BASE_ADDR,4,read_data,resp);
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
        automatic bit signed [31:0] a,b;
        forever begin
            wait(goden_data.size()!=0 && recev_data.size()!=0);
            a=goden_data.pop_front();
            b=recev_data.pop_front();
            $display("a=%x, b=%x",a,b);
        end
    end

    initial begin
        automatic bit resp;
        @(config_finish);
        repeat(5) @(posedge drdy);
        `ZYNQ.write_data(ADC_ENABLE_GPIO_BASEADDR,4,1'b1,resp);
        repeat(5)@(posedge drdy);
        forever begin
            @(negedge drdy);
            data_trans=$random();
            goden_data.push_back({{8{data_trans[23]}},data_trans});
        end
    end
    assign sclk=aclk;
    ads1675_model #(.W(48)) the_ads1675_model_Inst(
        sclk,aresetn,1'b1,
        sclk_p,sclk_n,
        drdy_p,drdy_n,
        dout_p,dout_n,
        data_trans
    );
    IBUFDS drdy_buf (.O(drdy), .I(drdy_p), .IB(drdy_n));
    `WRAPPER DUT
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
    .dout_n(dout_n),
    .dout_p(dout_p),
    .dr0(),
    .dr1(),
    .dr2(),
    .fpath(),
    .ll_cfg(),
    .lvds(),
    .pown(),
    .drdy_n(drdy_n),
    .drdy_p(drdy_p),
    .sclk_n(sclk_n),
    .sclk_p(sclk_p),
    .start());
endmodule