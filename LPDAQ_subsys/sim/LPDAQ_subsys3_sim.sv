`timescale 1ns/10ps

`define ZYNQ LPDAQ_subsys3_sim.UUT.LPDAQ_subsys3_i.processing_system7_0.inst
`define WRAPPER LPDAQ_subsys3_wrapper
module LPDAQ_subsys3_sim();
    localparam integer ADC_ENABLE_GPIO_BASEADDR = 32'h4120_0000;
    localparam integer RD_CNT_GPIO_BASEADDR = 32'h4121_0000;
    localparam integer DATA_BASEADDR = 32'h43c0_0000;
    localparam integer ROUND = 50;

    bit aclk,aresetn;
    wire temp_aclk,temp_aresetn;
    bit sck,dout,fsync;

    bit signed [31:0] goden_data[$]={};
    bit signed [31:0] recev_data[$];
    bit signed [23:0] data_trans;
    bit signed [31:0] data_recv;
    bit signed [23:0] cos;
    bit signed [19:0] cos1,cos2,cos3;

    bit [31:0] read_data;
    bit signed [31:0] data;
    bit signed [23:0] result;
    bit [31:0] addr,offset_addr;

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

        ->config_finish;
    end

    /*
     * simulate 
     */
    orthDds #(32,20,13) theOrthDdsInst_10000Hz(aclk,aresetn,1'b1,32'd429496,32'd0,,cos1);  ///< 10000Hz
    orthDds #(32,20,13) theOrthDdsInst_1000Hz(aclk,aresetn,1'b1,32'd42949,32'd0,,cos2);   ///< 1000Hz
    orthDds #(32,20,13) theOrthDdsInst_100Hz(aclk,aresetn,1'b1,32'd4294,32'd0,,cos3);    ///< 100Hz
    always_ff @( posedge aclk ) begin
        cos<=cos1+cos2+cos3;
    end
    initial begin
        automatic bit resp;
        @(config_finish);
        `ZYNQ.write_data(ADC_ENABLE_GPIO_BASEADDR,4,1'b1,resp);
        fork
            begin
                for(int i=0;i<500000;i++) begin
                    repeat(50) @(posedge fsync);
                    `ZYNQ.read_data(RD_CNT_GPIO_BASEADDR,4,read_data,resp);
                    if(read_data!=1'b0) begin
                        $display("rd_cnt=%d",read_data);
                        `ZYNQ.read_data(DATA_BASEADDR,4,data,resp);
                        result=data[0+:24];
                        recev_data.push_back(result);
                    end
                end
            end
        join
        // wait for data check finish
        repeat(5)@(posedge aclk);
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
        forever begin
            @(posedge fsync);
            data_trans=cos;
            goden_data.push_back({{8{data_trans[23]}},data_trans});
        end
    end

    ads127l01_512k_master_fsync_model the_ads127l01_512k_master_fsync_model_Inst(
        aclk,aresetn,1'b1,
        data_trans,
        sck,dout,fsync
    );
    `WRAPPER UUT
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
        .dout(dout),
        .fsync(fsync),
        .reset_n(),
        .sck(sck),
        .start());
endmodule