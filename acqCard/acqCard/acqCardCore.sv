/*
 * @Author: ZivFung 
 * @Date: 2020-12-01 21:08:15 
 * @Last Modified by: ZivFung
 * @Last Modified time: 2020-12-04 21:01:07
 */
`include "common.sv"
`include "acqCardDefine.sv"


module acqCardCore
    import AcqCard::*, Axi_pkg::*;
(
    input  wire                                                             clk,
    input  wire                                                             fifoOutClk,
    input  wire                                                             rst,
    input  wire                                                             fifoRst,
    input  wire                                                             sysEn,

    input  wire  [ADC_INPUT_NUM - 1 : 0]                        
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 ad_din,                             //From ADC
    input  wire  [ADC_INPUT_NUM - 1 : 0]                                    ad_dinValid,
    output logic [ADC_INPUT_NUM - 1 : 0]                                    ad_dinReady,

    output logic [DAC_OUTPUT_NUM - 1 : 0]                       
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 da_dout,                            //To DAC
    output logic [DAC_OUTPUT_NUM - 1 : 0]                                   da_doutValid,
    input  wire  [DAC_OUTPUT_NUM - 1 : 0]                                   da_doutReady,

    output logic [ADC_INPUT_NUM - 1 : 0]                        
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 acqInData_Dout,                 //To PC
    output logic [ADC_INPUT_NUM - 1 : 0]                                    acqInData_DoutValid,
    input  wire  [ADC_INPUT_NUM - 1 : 0]                                    acqInData_DoutReady,

    output logic [DAC_OUTPUT_NUM - 1 : 0]                       
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 acqOutData_Dout,                 //To PC
    output logic [DAC_OUTPUT_NUM - 1 : 0]                                   acqOutData_DoutValid,
    input  wire  [DAC_OUTPUT_NUM - 1 : 0]                                   acqOutData_DoutReady,
    
    input  wire  [DAC_OUTPUT_NUM - 1 : 0]                       
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 axiOutData_Din,                 //From PC
    input  wire  [DAC_OUTPUT_NUM - 1 : 0]                                   axiOutData_DinValid,
    output logic [DAC_OUTPUT_NUM - 1 : 0]                                   axiOutData_DinReady,

    output logic                                                            acqOutDataSyncFifo_full,
    output logic                                                            acqInDataSyncFifo_full,

    input  coComputeUnitFunc_t [COMPUTE_UNIT_SUM - 1 : 0]                   funcSel,

    input  wire  [INPUT_SELMAT_N - 1 : 0][7 : 0]       				        inputSelMatrix_sel,
    input  wire  [OUTPUT_SELMAT_N - 1 : 0][7 : 0]       				    outputSelMatrix_sel,


    input  wire  [COMPUTE_UNIT_PID_NUM - 1 : 0] 
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 compUnitpid_p,

    input  wire  [COMPUTE_UNIT_PID_NUM - 1 : 0] 
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 compUnitpid_i,

    input  wire  [COMPUTE_UNIT_PID_NUM - 1 : 0] 
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 compUnitpid_d,

    input  wire  [COMPUTE_UNIT_PID_NUM - 1 : 0] 
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 compUnitpid_n,

    input  wire  [COMPUTE_UNIT_PID_NUM - 1 : 0] 
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 compUnitpid_ts,

    input  wire  [COMPUTE_UNIT_PID_NUM - 1 : 0] 
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 compUnitpid_lim,   

    input  wire  [COMPUTE_UNIT_SUM - 1 : 0] 
                 [ACQ_CARD_DATA_DW - 1 : 0]                                 compUnit_constIn   
);
    
    logic [ADC_INPUT_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]                 ad_DinBuf;
    logic [ADC_INPUT_NUM - 1 : 0]                                           ad_DinShaked;
    logic [DAC_OUTPUT_NUM - 1 : 0]                                          da_DoutShaked;

    logic [DAC_OUTPUT_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]                core_daDout;
    logic [DAC_OUTPUT_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]                da_DoutBuf;

    always_comb begin
        for(int i = 0; i < ADC_INPUT_NUM; i++)begin
            ad_DinShaked[i] <= ad_dinValid[i] & ad_dinReady[i];
        end
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            da_DoutShaked[i] <= da_doutValid[i] & da_doutReady[i];
        end
    end

    always_ff@(posedge clk)begin
        if(rst)begin
            for(int i = 0; i < ADC_INPUT_NUM; i++)begin
                ad_dinReady[i] <= '0;
            end
        end
        else begin
            for(int i = 0; i < ADC_INPUT_NUM; i++)begin
                if(sysEn)begin
                    ad_dinReady[i] <= 1'b1;
                end
                else if(ad_DinShaked[i])begin
                    ad_dinReady[i] <= 1'b0;
                end
                else begin
                    ad_dinReady[i] <= ad_dinReady[i];
                end
            end
        end
    end

    always_ff@(posedge clk)begin
        if(rst)begin
            for(int i = 0; i < ADC_INPUT_NUM; i++)begin
                ad_DinBuf[i] <= '0;
            end
        end
        else begin
            for(int i = 0; i < ADC_INPUT_NUM; i++)begin
                if(ad_DinShaked[i])begin
                    ad_DinBuf[i] <= ad_din[i];
                end
            end
        end
    end
    
    logic  [DAC_OUTPUT_NUM - 1 : 0]                       
           [ACQ_CARD_DATA_DW - 1 : 0]                                 exDacDataFifo_Din;
    always_comb begin
        exDacDataFifo_Din = '0;
        axiOutData_DinReady = '0;
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            exDacDataFifo_Din[i] = axiOutData_Din[i];
            axiOutData_DinReady[i] = sysEn & axiOutData_DinValid[i];
        end
    end
    
    acqCardComputeCore computeCore
    (
        .clk(clk),
        .rst(rst),
        .sysEn(sysEn),

        .adDin(ad_DinBuf),
        .daDout(core_daDout),
        .exDacData_Din(exDacDataFifo_Din),

        .funcSel(funcSel),
        .inputSelMatrix_sel(inputSelMatrix_sel),
        .outputSelMatrix_sel(outputSelMatrix_sel),

        .compUnitpid_p(compUnitpid_p),
        .compUnitpid_i(compUnitpid_i),
        .compUnitpid_d(compUnitpid_d),
        .compUnitpid_n(compUnitpid_n),
        .compUnitpid_ts(compUnitpid_ts),
        .compUnitpid_lim(compUnitpid_lim),   
        .compUnit_constIn(compUnit_constIn)   
    );

    always_ff@(posedge clk)begin
        if(rst)begin
            for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
                da_DoutBuf[i] <= '0;
            end
        end
        else if(sysEn)begin
            for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
                da_DoutBuf[i] <= core_daDout[i];
            end
        end
    end

    always_comb begin
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            da_dout[i] <= da_DoutBuf[i];
        end
    end


    always_ff@(posedge clk)begin
        if(rst)begin
            for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
                da_doutValid[i] <= '0;
            end
        end
        else begin
            for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
                if(sysEn)begin
                    da_doutValid[i] <= 1'b1;
                end
                else if(da_DoutShaked[i])begin
                    da_doutValid[i] <= 1'b0;
                end
                else begin
                    da_doutValid[i] <= da_doutValid[i];
                end
            end
        end
    end
    
    logic [ADC_INPUT_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]     acqInDataFifo_Din;
    logic [ADC_INPUT_NUM - 1 : 0]                               acqInDataFifo_DinValid;
    logic [ADC_INPUT_NUM - 1 : 0]                               acqInDataFifo_DinReady;

    logic [DAC_OUTPUT_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]    acqOutDataFifo_Din;
    logic [DAC_OUTPUT_NUM - 1 : 0]                              acqOutDataFifo_DinValid;
    logic [DAC_OUTPUT_NUM - 1 : 0]                              acqOutDataFifo_DinReady;


    always_comb begin : AcqInputFifo_Assign_Proc
        acqInDataFifo_Din = '0;
        acqInDataFifo_DinValid = '0;
        for(int i = 0; i < ADC_INPUT_NUM; i++)begin
            acqInDataFifo_Din[i] = ad_DinBuf[i];
            acqInDataFifo_DinValid[i] = sysEn & acqInDataFifo_DinReady[i];
        end
    end

    always_comb begin : AcqOutputFifo_Assign_Proc
        acqOutDataFifo_Din = '0;
        acqOutDataFifo_DinValid = '0;
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            acqOutDataFifo_Din[i] = da_DoutBuf[i];
            acqOutDataFifo_DinValid[i] = sysEn & acqOutDataFifo_DinReady[i];
        end
    end
    
        
`ifdef MODELSIM
    generate
        genvar i;
        for(i = 0; i < ADC_INPUT_NUM; i++)begin : Acq_Input_SyncFifo
            dcFifo#(               //Fall-through
                .DW(ACQ_CARD_DATA_DW),
                .DEPTH(ACQ_INPUT_SYNC_FIFO_DEPTH)
            )acqIndataSyncFifo(
                .clk_in(clk),
                .clk_out(fifoOutClk),
                .rst_n(~rst & ~fifoRst),
                .flush(1'b0),

                .din_valid(acqInDataFifo_DinValid[i]),
                .din_ready(acqInDataFifo_DinReady[i]),
                .din(acqInDataFifo_Din[i]),

                .dout_ready(acqInData_DoutReady[i]),
                .dout_valid(acqInData_DoutValid[i]),
                .dout(acqInData_Dout[i]),
                .dataCount()
            );
        end

        for(i = 0; i < DAC_OUTPUT_NUM; i++)begin : Acq_Output_SyncFifo
            dcFifo#(               //Fall-through
                .DW(ACQ_CARD_DATA_DW),
                .DEPTH(ACQ_OUTPUT_SYNC_FIFO_DEPTH)
            )acqOutdataSyncFifo(
                .clk_in(clk),
                .clk_out(fifoOutClk),
                .rst_n(~rst & ~fifoRst),
                .flush(1'b0),

                .din_valid(acqOutDataFifo_DinValid[i]),
                .din_ready(acqOutDataFifo_DinReady[i]),
                .din(acqOutDataFifo_Din[i]),

                .dout_ready(acqOutData_DoutReady[i]),
                .dout_valid(acqOutData_DoutValid[i]),
                .dout(acqOutData_Dout[i]),
                .dataCount()
            );
        end
        
    endgenerate
    always_comb begin
        acqOutDataSyncFifo_full = |(~acqInDataFifo_DinReady);
        acqInDataSyncFifo_full = |(~acqOutDataFifo_DinReady);
    end
`endif

`ifdef VIVADO
//    logic [ADC_INPUT_NUM - 1 : 0]                                   inSyncFifoAlmostFull;
//    logic [DAC_OUTPUT_NUM - 1 : 0]                                  outSyncFifoAlmostFull;
//    logic [ADC_INPUT_NUM - 1 : 0]                        
//          [ACQ_CARD_DATA_DW - 1 : 0]                                 acqInRegSlice_Dout;
//    logic [ADC_INPUT_NUM - 1 : 0]                                    acqInRegSlice_DoutValid;
//    logic [ADC_INPUT_NUM - 1 : 0]                                    acqInRegSlice_DoutReady;
//    logic [DAC_OUTPUT_NUM - 1 : 0]                       
//          [ACQ_CARD_DATA_DW - 1 : 0]                                 acqOutReglice_Dout;
//    logic [DAC_OUTPUT_NUM - 1 : 0]                                   acqOutReglice_DoutValid;
//    logic [DAC_OUTPUT_NUM - 1 : 0]                                   acqOutReglice_DoutReady;
//    generate
//        genvar i;
//        for(i = 0; i < ADC_INPUT_NUM; i++)begin : Acq_Input_SyncFifo
//            axis_data_fifo_0 acqIndataSyncFifo(
//                .s_axis_aresetn(~rst & ~fifoRst),
//                .s_axis_aclk(clk),
//                .s_axis_tvalid(acqInDataFifo_DinValid[i]),
//                .s_axis_tready(acqInDataFifo_DinReady[i]),
//                .s_axis_tdata(acqInDataFifo_Din[i]),
//                .m_axis_aclk(fifoOutClk),
//                .m_axis_tvalid(acqInData_DoutValid[i]),
//                .m_axis_tready(acqInData_DoutReady[i]),
//                .m_axis_tdata(acqInData_Dout[i]),
//                .almost_full(inSyncFifoAlmostFull[i])
//            );
//            axis_register_slice_0 inFifoRegSlice(
//                .aclk(fifoOutClk),
//                .aresetn(~rst & ~fifoRst),
//                .s_axis_tvalid(acqInRegSlice_DoutValid[i]),
//                .s_axis_tready(acqInRegSlice_DoutReady[i]),
//                .s_axis_tdata(acqInRegSlice_Dout[i]),
//                .m_axis_tvalid(acqInData_DoutValid[i]),
//                .m_axis_tready(acqInData_DoutReady[i]),
//                .m_axis_tdata(acqInData_Dout[i])
//            );
//        end

//        for(i = 0; i < DAC_OUTPUT_NUM; i++)begin : Acq_Output_SyncFifo
//            axis_data_fifo_0 acqOutdataSyncFifo(
//                .s_axis_aresetn(~rst & ~fifoRst),
//                .s_axis_aclk(clk),
//                .s_axis_tvalid(acqOutDataFifo_DinValid[i]),
//                .s_axis_tready(acqOutDataFifo_DinReady[i]),
//                .s_axis_tdata(acqOutDataFifo_Din[i]),
//                .m_axis_aclk(fifoOutClk),
//                .m_axis_tvalid(acqOutData_DoutValid[i]),
//                .m_axis_tready(acqOutData_DoutReady[i]),
//                .m_axis_tdata(acqOutData_Dout[i]),
//                .almost_full(outSyncFifoAlmostFull[i])
//            );
//            axis_register_slice_0 outFifoRegSlice(
//                .aclk(fifoOutClk),
//                .aresetn(~rst & ~fifoRst),
//                .s_axis_tvalid(acqOutReglice_DoutValid[i]),
//                .s_axis_tready(acqOutReglice_DoutReady[i]),
//                .s_axis_tdata(acqOutReglice_Dout[i]),
//                .m_axis_tvalid(acqOutData_DoutValid[i]),
//                .m_axis_tready(acqOutData_DoutReady[i]),
//                .m_axis_tdata(acqOutData_Dout[i])
//            );
//        end
//    endgenerate
//    always_comb begin
//        acqOutDataSyncFifo_full = |(inSyncFifoAlmostFull);
//        acqInDataSyncFifo_full = |(outSyncFifoAlmostFull);
//    end

    always_comb begin
        for(int i = 0; i < ADC_INPUT_NUM; i++)begin
            acqInData_DoutValid[i] = acqInDataFifo_DinValid[i];
            acqInData_Dout[i] = acqInDataFifo_Din[i];
            acqInDataFifo_DinReady[i] = acqInData_DoutReady[i];
        end
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            acqOutData_DoutValid[i] = acqOutDataFifo_DinValid[i];
            acqOutData_Dout[i] = acqOutDataFifo_Din[i];
            acqOutDataFifo_DinReady[i] = acqOutData_DoutReady[i];
        end
    end
    always_comb begin
        acqOutDataSyncFifo_full = 0;
        acqInDataSyncFifo_full  = 0;
    end
`endif

endmodule