`timescale 1ns/10ps

module zynq_sim_tb();
    bit clk,rstn;
    wire temp_clk,temp_rstn;
    logic [31:0]gpio_io_o_0;
    bit resp;
    bit [31:0] read_data;
    bit [15:0] irq_status;
    always #50 clk=~clk;
    //reset PS
    initial begin
        rstn=0;
        #100 rstn=1;
    end
    initial begin
        repeat(5) @(posedge clk);
        //reset PL
        zynq_sim_tb.UUT.zynq_sim_i.processing_system7_0.inst.set_stop_on_error(1'b1);
        zynq_sim_tb.UUT.zynq_sim_i.processing_system7_0.inst.set_debug_level_info(1'b1);
        zynq_sim_tb.UUT.zynq_sim_i.processing_system7_0.inst.fpga_soft_reset(32'h1);
        zynq_sim_tb.UUT.zynq_sim_i.processing_system7_0.inst.fpga_soft_reset(32'h0);
        $display("PL reset complete...");
        zynq_sim_tb.UUT.zynq_sim_i.processing_system7_0.inst.write_data(32'h4120_0000,4,32'h1111_1111,resp);
        zynq_sim_tb.UUT.zynq_sim_i.processing_system7_0.inst.write_data(32'h4000_0000,4,32'hABCD_1854,resp);
        zynq_sim_tb.UUT.zynq_sim_i.processing_system7_0.inst.read_data(32'h4000_0000,4,read_data,resp);
        if(read_data==32'hABCD_1854) begin
            $display("write read mem data success...");
        end
        else begin
            $display("write read mem data error");
        end
        irq_status='1;
        zynq_sim_tb.UUT.zynq_sim_i.processing_system7_0.inst.read_interrupt(irq_status);
        $displayb(irq_status);
        $finish;
    end
    always @(gpio_io_o_0) begin
        $display("led toggle...");
    end
    assign temp_clk=clk;
    assign temp_rstn=rstn;
    zynq_sim_wrapper UUT
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
    .FIXED_IO_ps_clk(temp_clk),
    .FIXED_IO_ps_porb(temp_rstn),
    .FIXED_IO_ps_srstb(temp_rstn),
    .gpio_io_o_0(gpio_io_o_0));

endmodule