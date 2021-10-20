/*
 * @Author: ZivFung 
 * @Date: 2020-12-02 17:02:50 
 * @Last Modified by: ZivFung
 * @Last Modified time: 2020-12-04 21:01:48
 */
`include "common.sv"
`include "acqCardDefine.sv"

module acqCard_v0
    import AcqCard::*, Axi_pkg::*;
#(
    parameter AXI_CTRL_BASEADDR = 32'h80000000,
    parameter AXI_DATA_BASEADDR = 32'h90000000
)
(
    Axi4LiteIf.slave                                                    s_axi_lite_ctrl,     
    Axi4FullIf.slave                                                    s_axi_data,

    input  wire                                                         core_clk,
    input  wire                                                         rst,
    (*mark_debug = "true"*)
    input  wire                                                         sysEn,

    input  wire  [ADC_INPUT_NUM - 1 : 0]                                    
                 [ACQ_CARD_DATA_DW - 1 : 0]                             ad_din,                             //From ADC
    input  wire  [ADC_INPUT_NUM - 1 : 0]                                ad_dinValid,
    output logic [ADC_INPUT_NUM - 1 : 0]                                ad_dinReady,

    output logic [DAC_OUTPUT_NUM - 1 : 0]                                   
                 [ACQ_CARD_DATA_DW - 1 : 0]                             da_dout,                            //To DAC
    output logic [DAC_OUTPUT_NUM - 1 : 0]                               da_doutValid,
    input  wire  [DAC_OUTPUT_NUM - 1 : 0]                               da_doutReady,

    output logic [DO_NUM - 1 : 0]                                       acq_do,
    output logic [ADC_INPUT_NUM - 1 : 0]                                adc_inz_switch,
    output logic [DAC_OUTPUT_NUM - 1 : 0]                               dac_outfil_switch,

    output logic                                                        interrupt
                                               
);          

    logic [ACQ_CARD_CTRL_REG_NUM - 1 : 0][ACQ_CARD_CTRL_REG_DW - 1 :0]  acqCardCtrl;
    (*mark_debug = "true"*)
    logic                                                               acqCardSwRst;
    (*mark_debug = "true"*)
    logic                                                               acqCardFifoRst;
    always_comb begin
        acqCardSwRst    = acqCardCtrl[0][0];
        acqCardFifoRst  = acqCardCtrl[0][1];
    end


    coComputeUnitFunc_t [COMPUTE_UNIT_SUM - 1 : 0]                      funcSel;

    logic [INPUT_SELMAT_N - 1 : 0][7 : 0]       		                inputSelMatrix_sel;
    logic [OUTPUT_SELMAT_N - 1 : 0][7 : 0]       			            outputSelMatrix_sel;

    logic [COMPUTE_UNIT_PID_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]      compUnitpid_p;
    logic [COMPUTE_UNIT_PID_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]      compUnitpid_i;
    logic [COMPUTE_UNIT_PID_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]      compUnitpid_d;
    logic [COMPUTE_UNIT_PID_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]      compUnitpid_n;
    logic [COMPUTE_UNIT_PID_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]      compUnitpid_ts;
    logic [COMPUTE_UNIT_PID_NUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]      compUnitpid_lim;;
    logic [COMPUTE_UNIT_SUM - 1 : 0][ACQ_CARD_DATA_DW - 1 : 0]          compUnit_constIn;

    
    (*mark_debug = "true"*)
    logic [ADC_INPUT_NUM - 1 : 0]                                   
          [ACQ_CARD_DATA_DW - 1 : 0]                                    acqInData_Dout;                 //To PC
    (*mark_debug = "true"*)
    logic [ADC_INPUT_NUM - 1 : 0]                                       acqInData_DoutValid;
    (*mark_debug = "true"*)
    logic [ADC_INPUT_NUM - 1 : 0]                                       acqInData_DoutReady;

    logic [DAC_OUTPUT_NUM - 1 : 0]                                  
          [ACQ_CARD_DATA_DW - 1 : 0]                                    acqOutData_Dout;                //To PC
    logic [DAC_OUTPUT_NUM - 1 : 0]                                      acqOutData_DoutValid;
    logic [DAC_OUTPUT_NUM - 1 : 0]                                      acqOutData_DoutReady;
    
    logic [DAC_OUTPUT_NUM - 1 : 0]                                  
          [ACQ_CARD_DATA_DW - 1 : 0]                                    axiOutData_Din;                 //From PC
    logic [DAC_OUTPUT_NUM - 1 : 0]                                      axiOutData_DinValid;
    logic [DAC_OUTPUT_NUM - 1 : 0]                                      axiOutData_DinReady;
    logic [DAC_OUTPUT_NUM - 1 : 0]                                      axiOutData_DinValid_ctred;
    logic [DAC_OUTPUT_NUM - 1 : 0]                                      axiOutData_DinReady_ctred;
    
    
    logic [DO_CTRL_REG_NUM - 1 : 0]                                  
          [ACQ_CARD_DATA_DW - 1 : 0]                                    dofifoData_Din;                 //From PC
    logic [DO_CTRL_REG_NUM - 1 : 0]                                     dofifoData_DinValid;
    logic [DO_CTRL_REG_NUM - 1 : 0]                                     dofifoData_DinReady;
    logic [DO_CTRL_REG_NUM - 1 : 0]                                     dofifoData_DinValid_ctred;
    logic [DO_CTRL_REG_NUM - 1 : 0]                                     dofifoData_DinReady_ctred;

    (*mark_debug = "true"*)
    logic [ADC_INPUT_NUM + DAC_OUTPUT_NUM - 1 : 0]
          [ACQ_CARD_DATA_DW - 1 : 0]                                    fifo2AxiDin;                    //To PC
    (*mark_debug = "true"*)
    logic [ADC_INPUT_NUM + DAC_OUTPUT_NUM - 1 : 0]                      fifo2AxiDinValid;
    (*mark_debug = "true"*)
    logic [ADC_INPUT_NUM + DAC_OUTPUT_NUM - 1 : 0]                      fifo2AxiDinReady;
    
    logic [DAC_OUTPUT_NUM + DO_CTRL_REG_NUM -1: 0]
          [ACQ_CARD_DATA_DW - 1 : 0]                                    fifo2AxiDout;                   //From PC
    logic [DAC_OUTPUT_NUM + DO_CTRL_REG_NUM -1: 0]                      fifo2AxiDoutValid;
    logic [DAC_OUTPUT_NUM + DO_CTRL_REG_NUM -1: 0]                      fifo2AxiDoutReady;

    logic                                                               acq_inputSyncFifo_full;
    logic                                                               acq_outputSyncFifo_full;    
    
    always_comb begin
        acq_do = '0;
        dofifoData_DinReady = '0;
        for(int i = 0; i < DO_CTRL_REG_NUM; i++)begin
            acq_do = dofifoData_Din[0][DO_NUM - 1 : 0];
            dofifoData_DinReady[i] = sysEn & dofifoData_DinValid[i];
        end
    end

    acqCardCore core
    (
        .clk(core_clk),
        .fifoOutClk(s_axi_data.clk),
        .rst(rst | acqCardSwRst),
        .sysEn(sysEn),
        .fifoRst(acqCardFifoRst),

        .ad_din(ad_din),                             //From ADC
        .ad_dinValid(ad_dinValid),
        .ad_dinReady(ad_dinReady),

        .da_dout(da_dout),                            //To DAC
        .da_doutValid(da_doutValid),
        .da_doutReady(da_doutReady),

        .acqInData_Dout(acqInData_Dout),                 //To PC
        .acqInData_DoutValid(acqInData_DoutValid),
        .acqInData_DoutReady(acqInData_DoutReady),

        .acqOutData_Dout(acqOutData_Dout),                 //To PC
        .acqOutData_DoutValid(acqOutData_DoutValid),
        .acqOutData_DoutReady(acqOutData_DoutReady),
                  
        .axiOutData_Din(axiOutData_Din),                 //From PC
        .axiOutData_DinValid(axiOutData_DinValid),
        .axiOutData_DinReady(axiOutData_DinReady),
    
        .acqOutDataSyncFifo_full(acq_outputSyncFifo_full),
        .acqInDataSyncFifo_full(acq_inputSyncFifo_full),

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


    /***********************************************  AXI LITE LOGIC  *******************************************************/
    (*mark_debug = "true"*)
    logic [ACQ_CARD_REG_NUM - 1 : 0][ACQ_CARD_CTRL_REG_DW - 1 : 0]       ctrl_reg;
    logic [ACQ_CARD_REG_NUM - 1 : 0][CTRL_REG_SYNC_STG - 1 : 0]
          [ACQ_CARD_CTRL_REG_DW - 1 : 0]                                        ctrl_reg_sync;

    always_ff@(posedge core_clk)begin
        if(CTRL_REG_SYNC_STG == 1)begin
            for(int i = 0; i < 2 ** ACQ_CARD_REG_NUM_W - 1; i++)begin
                ctrl_reg_sync[i] <= ctrl_reg[i];
            end
        end
        else begin
            for(int i = 0; i < 2 ** ACQ_CARD_REG_NUM_W - 1; i++)begin
                ctrl_reg_sync[i] <= {ctrl_reg_sync[i][CTRL_REG_SYNC_STG-2 : 0], ctrl_reg[i]};
            end
        end
    end

    (*mark_debug = "true"*)
    logic [ST_REG_NUM - 1 : 0][ACQ_CARD_CTRL_REG_DW - 1 : 0]                                 acqState;

    axiLite_mem_v1
    #(
        .BASE_ADDR(AXI_CTRL_BASEADDR),
        .MEM_AW(MEM_AW),//.MEM_AW(ACQ_CARD_REG_NUM_W + ST_REG_NUM_W),
        .ST_REG_NUM(ST_REG_NUM)//.ST_REG_NUM(ST_REG_NUM)
    )acqCardCtrlReg(
        .s_axi_mem(s_axi_lite_ctrl),
        .stateIn(acqState),
        .mem_data(ctrl_reg)
    );

    always_comb begin : CTRL_REG_ASSIGN_PROC
        
        for(int i = 0; i < ACQ_CARD_CTRL_REG_NUM; i++)begin
            acqCardCtrl[i] = ctrl_reg_sync[i][CTRL_REG_SYNC_STG-1];
        end

        for(int i = 0; i < INPUT_SELMAT_SEL_REG_NUM; i++)begin
            inputSelMatrix_sel[i] = ctrl_reg_sync[i + ACQ_CARD_CTRL_REG_NUM][CTRL_REG_SYNC_STG-1][7 : 0];
        end

        for(int i = 0; i < OUTPUT_SELMAT_SEL_REG_NUM; i++)begin
            outputSelMatrix_sel[i] = ctrl_reg_sync[i + ACQ_CARD_CTRL_REG_NUM + 
                                                INPUT_SELMAT_SEL_REG_NUM][CTRL_REG_SYNC_STG-1][7 : 0];
        end

        for(int i = 0; i < COMPUTE_UNIT_FUNC_SEL_REG_NUM; i++)begin
            case (ctrl_reg_sync[i + ACQ_CARD_CTRL_REG_NUM + 
                            INPUT_SELMAT_SEL_REG_NUM + 
                            OUTPUT_SELMAT_SEL_REG_NUM][CTRL_REG_SYNC_STG-1][3 : 0])
                4'b0000: funcSel[i] = ADD;
                4'b0001: funcSel[i] = SUB;
                4'b0010: funcSel[i] = MUL;
                4'b0011: funcSel[i] = DIV;
                4'b0100: funcSel[i] = ADD_C;
                4'b0101: funcSel[i] = SUB_C;
                4'b0110: funcSel[i] = MUL_C;
                4'b0111: funcSel[i] = DIV_C;
                4'b1000: funcSel[i] = PID;
                default:funcSel[i] = ADD;
            endcase
        end

        for(int i = 0; i < COMPUTE_UNIT_CONST_IN_REG_NUM; i++)begin
            compUnit_constIn[i] = ctrl_reg_sync[i + ACQ_CARD_CTRL_REG_NUM + 
                                        INPUT_SELMAT_SEL_REG_NUM + 
                                        OUTPUT_SELMAT_SEL_REG_NUM +
                                        COMPUTE_UNIT_FUNC_SEL_REG_NUM][CTRL_REG_SYNC_STG-1][ACQ_CARD_DATA_DW - 1 : 0];
        end


        for(int i = 0; i < COMPUTE_UNIT_PID_NUM; i++)begin
            compUnitpid_p[i]                        = ctrl_reg_sync[i * PID_UNIT_PARAM_NUM + ACQ_CARD_CTRL_REG_NUM + 
                                                                INPUT_SELMAT_SEL_REG_NUM + 
                                                                OUTPUT_SELMAT_SEL_REG_NUM +
                                                                COMPUTE_UNIT_FUNC_SEL_REG_NUM + 
                                                                COMPUTE_UNIT_CONST_IN_REG_NUM][CTRL_REG_SYNC_STG-1][ACQ_CARD_DATA_DW - 1 : 0];

            compUnitpid_i[i]                        = ctrl_reg_sync[i * PID_UNIT_PARAM_NUM + 1 + ACQ_CARD_CTRL_REG_NUM + 
                                                                INPUT_SELMAT_SEL_REG_NUM + 
                                                                OUTPUT_SELMAT_SEL_REG_NUM +
                                                                COMPUTE_UNIT_FUNC_SEL_REG_NUM + 
                                                                COMPUTE_UNIT_CONST_IN_REG_NUM][CTRL_REG_SYNC_STG-1][ACQ_CARD_DATA_DW - 1 : 0];
                                                                
            compUnitpid_d[i]                        = ctrl_reg_sync[i * PID_UNIT_PARAM_NUM + 2 + ACQ_CARD_CTRL_REG_NUM + 
                                                                INPUT_SELMAT_SEL_REG_NUM + 
                                                                OUTPUT_SELMAT_SEL_REG_NUM +
                                                                COMPUTE_UNIT_FUNC_SEL_REG_NUM + 
                                                                COMPUTE_UNIT_CONST_IN_REG_NUM][CTRL_REG_SYNC_STG-1][ACQ_CARD_DATA_DW - 1 : 0];

            compUnitpid_n[i]                        = ctrl_reg_sync[i * PID_UNIT_PARAM_NUM  + 3 + ACQ_CARD_CTRL_REG_NUM + 
                                                                INPUT_SELMAT_SEL_REG_NUM + 
                                                                OUTPUT_SELMAT_SEL_REG_NUM +
                                                                COMPUTE_UNIT_FUNC_SEL_REG_NUM + 
                                                                COMPUTE_UNIT_CONST_IN_REG_NUM][CTRL_REG_SYNC_STG-1][ACQ_CARD_DATA_DW - 1 : 0];

            compUnitpid_ts[i]                       = ctrl_reg_sync[i * PID_UNIT_PARAM_NUM  + 4 + ACQ_CARD_CTRL_REG_NUM + 
                                                                INPUT_SELMAT_SEL_REG_NUM + 
                                                                OUTPUT_SELMAT_SEL_REG_NUM +
                                                                COMPUTE_UNIT_FUNC_SEL_REG_NUM + 
                                                                COMPUTE_UNIT_CONST_IN_REG_NUM][CTRL_REG_SYNC_STG-1][ACQ_CARD_DATA_DW - 1 : 0];

            compUnitpid_lim[i]                      = ctrl_reg_sync[i * PID_UNIT_PARAM_NUM  + 5 + ACQ_CARD_CTRL_REG_NUM + 
                                                                INPUT_SELMAT_SEL_REG_NUM + 
                                                                OUTPUT_SELMAT_SEL_REG_NUM +
                                                                COMPUTE_UNIT_FUNC_SEL_REG_NUM + 
                                                                COMPUTE_UNIT_CONST_IN_REG_NUM][CTRL_REG_SYNC_STG-1][ACQ_CARD_DATA_DW - 1 : 0];
        end

        for(int i = 0; i < DAC_OUFIL_SWITCH_REG_NUM; i++)begin
            for(int j = 0; j < DAC_OUTPUT_NUM; j++)begin
                dac_outfil_switch[j + (i * ACQ_CARD_CTRL_REG_DW)]= ctrl_reg_sync[i + ACQ_CARD_CTRL_REG_NUM + 
                                                                INPUT_SELMAT_SEL_REG_NUM + 
                                                                OUTPUT_SELMAT_SEL_REG_NUM +
                                                                COMPUTE_UNIT_FUNC_SEL_REG_NUM + 
                                                                COMPUTE_UNIT_CONST_IN_REG_NUM +
                                                                COMPUTE_UNIT_PID_NUM * PID_UNIT_PARAM_NUM][CTRL_REG_SYNC_STG-1][j];   
            end
        end
        
        for(int i = 0; i < ADC_INZ_SWITCH_REG_NUM; i++)begin
            for(int j = 0; j < ADC_INPUT_NUM; j++)begin
                adc_inz_switch[j + (i * ACQ_CARD_CTRL_REG_DW)]= ctrl_reg_sync[i + ACQ_CARD_CTRL_REG_NUM + 
                                                                INPUT_SELMAT_SEL_REG_NUM + 
                                                                OUTPUT_SELMAT_SEL_REG_NUM +
                                                                COMPUTE_UNIT_FUNC_SEL_REG_NUM + 
                                                                COMPUTE_UNIT_CONST_IN_REG_NUM +
                                                                COMPUTE_UNIT_PID_NUM * PID_UNIT_PARAM_NUM +
                                                                DAC_OUFIL_SWITCH_REG_NUM][CTRL_REG_SYNC_STG-1][j];   
            end
        end
        
//        for(int i = 0; i < DAC_OUFIL_SWITCH_REG_NUM; i++)begin
//            for(int j = 0; j < ACQ_CARD_CTRL_REG_DW; j++)begin
//                dac_outfil_switch[j + (i * ACQ_CARD_CTRL_REG_DW)]= ctrl_reg_sync[i + ACQ_CARD_CTRL_REG_NUM + 
//                                                                INPUT_SELMAT_SEL_REG_NUM + 
//                                                                OUTPUT_SELMAT_SEL_REG_NUM +
//                                                                COMPUTE_UNIT_FUNC_SEL_REG_NUM + 
//                                                                COMPUTE_UNIT_CONST_IN_REG_NUM +
//                                                                COMPUTE_UNIT_PID_NUM * PID_UNIT_PARAM_NUM +
//                                                                DO_CTRL_REG_NUM + 
//                                                                ADC_INZ_SWITCH_REG_NUM][CTRL_REG_SYNC_STG-1][j];   
//            end
//        end
        
    end
    /***********************************************  FIFO LOGIC  *******************************************************/
    (*mark_debug = "true"*)
    logic [$clog2(ACQ_INPUT_FIFO_DEPTH): 0]                                    inFifoThreshold;
    (*mark_debug = "true"*)
    logic [ADC_INPUT_NUM - 1 : 0][$clog2(ACQ_INPUT_FIFO_DEPTH): 0]             inFifoDataCount;
    (*mark_debug = "true"*)
    logic [$clog2(ACQ_OUTPUT_FIFO_DEPTH): 0]                                   outFifoThreshold;
    (*mark_debug = "true"*)
    logic [DAC_OUTPUT_NUM - 1 : 0][$clog2(ACQ_OUTPUT_FIFO_DEPTH): 0]           outFifoDataCount; 
    (*mark_debug = "true"*)
    logic                                                                       inFifoAlmostFull, outFifoAlmostFull;
    (*mark_debug = "true"*)
    logic                                                                       inFifoFull, outFifoFull;
    logic [1 : 0]                                                               interruptEnable;
    logic                                                                       synEnable;
    
//    logic[ADC_INPUT_NUM - 1 : 0][31 : 0]    acqInDataFifo_Count;
//    logic[DAC_OUTPUT_NUM - 1 : 0][31 : 0]   acqOutDataFifo_Count;
//    logic[DAC_OUTPUT_NUM - 1 : 0][31 : 0]   axiOutDataFifo_Count;
    (*mark_debug = "true"*)
    logic [DAC_OUTPUT_NUM - 1 : 0][$clog2(ACQ_OUTPUT_FIFO_DEPTH): 0]           axioutFifoDataCount;
    logic [DO_CTRL_REG_NUM - 1 : 0][$clog2(ACQ_OUTPUT_FIFO_DEPTH): 0]          doFifoDataCount;
    
    always_comb begin : Acq_Card_State
        inFifoFull = |(~acqInData_DoutReady);
        outFifoFull = |(~acqOutData_DoutReady);

        inFifoThreshold = acqCardCtrl[1][$clog2(ACQ_INPUT_FIFO_DEPTH): 0];
        outFifoThreshold = acqCardCtrl[2][$clog2(ACQ_OUTPUT_FIFO_DEPTH): 0];

        interruptEnable = acqCardCtrl[3][1 : 0];
        
        synEnable = acqCardCtrl[4][0];

        inFifoAlmostFull = inFifoDataCount[0] > inFifoThreshold;
        outFifoAlmostFull = outFifoDataCount[0] > outFifoThreshold;

        acqState = '0;
        acqState[0][0] = acqInData_DoutReady[0];
        acqState[0][1] = acqOutData_DoutReady[0];
        acqState[0][2] = inFifoFull;
        acqState[0][3] = outFifoFull;
        acqState[0][4] = inFifoAlmostFull;
        acqState[0][5] = outFifoAlmostFull;
        
        for(int i = 0; i < ADC_INPUT_NUM; i++)begin
            acqState[1 + i]= inFifoDataCount[i] ;
        end
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            acqState[1 + i + ADC_INPUT_NUM]= outFifoDataCount[i];
        end
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            acqState[1 + i + ADC_INPUT_NUM + DAC_OUTPUT_NUM]= axioutFifoDataCount[i];
        end
        for(int i = 0; i < DO_CTRL_REG_NUM; i++)begin
            acqState[1 + i + ADC_INPUT_NUM + DAC_OUTPUT_NUM + DAC_OUTPUT_NUM]= doFifoDataCount[i];
        end
    end

    always_ff@(posedge s_axi_lite_ctrl.clk or negedge s_axi_lite_ctrl.reset_n)begin
        if(~s_axi_lite_ctrl.reset_n)begin
            interrupt <= '0;
        end
        else begin
            interrupt <= |(interruptEnable & {outFifoAlmostFull, inFifoAlmostFull});
        end
    end
    
`ifdef MODELSIM
    generate
        genvar i;
        for(i = 0; i < ADC_INPUT_NUM; i++)begin : inputDataFifo
            fifo#(
                .DW(ACQ_CARD_DATA_DW),
                .DEPTH(ACQ_INPUT_FIFO_DEPTH)
            )acqInDataFifo(
                .clk(s_axi_data.clk),
                .rst_n(s_axi_data.reset_n & ~rst & ~acqCardSwRst & ~acqCardFifoRst),
                .flush(1'b0),

                .din_valid(acqInData_DoutValid[i]),
                .din_ready(acqInData_DoutReady[i]),
                .din(acqInData_Dout[i]),

                .dout_ready(fifo2AxiDinReady[i]),
                .dout_valid(fifo2AxiDinValid[i]),
                .dout(fifo2AxiDin[i]),
                .dataCount(inFifoDataCount[i])
            );
        end

        for(i = 0; i < DAC_OUTPUT_NUM; i++)begin : outputDataFifo
            fifo#(
                .DW(ACQ_CARD_DATA_DW),
                .DEPTH(ACQ_OUTPUT_FIFO_DEPTH)
            )acqOutDataFifo(
                .clk(s_axi_data.clk),
                .rst_n(s_axi_data.reset_n & ~rst & ~acqCardSwRst & ~acqCardFifoRst),
                .flush(1'b0),

                .din_valid(acqOutData_DoutValid[i]),
                .din_ready(acqOutData_DoutReady[i]),
                .din(acqOutData_Dout[i]),

                .dout_ready(fifo2AxiDinReady[i + ADC_INPUT_NUM]),
                .dout_valid(fifo2AxiDinValid[i + ADC_INPUT_NUM]),
                .dout(fifo2AxiDin[i + ADC_INPUT_NUM]),
                .dataCount(outFifoDataCount[i])
            );
        end

    endgenerate
`endif
`ifdef VIVADO
    (*mark_debug = "true"*)
    logic[ADC_INPUT_NUM - 1 : 0][31 : 0]    acqInDataFifo_wrCount, acqInDataFifo_rdCount;
    (*mark_debug = "true"*)
    logic[DAC_OUTPUT_NUM - 1 : 0][31 : 0]   acqOutDataFifo_wrCount, acqOutDataFifo_rdCount;
    (*mark_debug = "true"*)
    logic[DAC_OUTPUT_NUM - 1 : 0][31 : 0]   axiOutDataFifo_wrCount, axiOutDataFifo_rdCount;
    logic[DO_CTRL_REG_NUM -1 : 0][31 : 0]   dofifo_wrCount        , dofifo_rdcount        ;
    
    always_comb begin
        for(int i = 0; i < ADC_INPUT_NUM; i++)begin
            inFifoDataCount[i]      = acqInDataFifo_rdCount[i][$clog2(ACQ_INPUT_FIFO_DEPTH): 0];      
        end
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            outFifoDataCount[i]     = acqOutDataFifo_rdCount[i][$clog2(ACQ_INPUT_FIFO_DEPTH): 0];           
        end
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            axioutFifoDataCount[i]  = axiOutDataFifo_wrCount[i][$clog2(ACQ_INPUT_FIFO_DEPTH): 0];           
        end
        for(int i = 0; i < DO_CTRL_REG_NUM; i++)begin
            doFifoDataCount[i]  = dofifo_wrCount[i][$clog2(ACQ_INPUT_FIFO_DEPTH): 0];           
        end
        
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            axiOutData_DinValid[i]  = axiOutData_DinValid_ctred[i] & ~synEnable;           
        end
        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
            axiOutData_DinReady_ctred[i]  = axiOutData_DinReady[i] & ~synEnable;           
        end
        for(int i = 0; i < DO_CTRL_REG_NUM; i++)begin
            dofifoData_DinValid[i]  = dofifoData_DinValid_ctred[i] & ~synEnable;           
        end
        for(int i = 0; i < DO_CTRL_REG_NUM; i++)begin
            dofifoData_DinReady_ctred[i]  = dofifoData_DinReady[i] & ~synEnable;           
        end
    end  
    
    generate
        genvar i;
        for(i = 0; i < ADC_INPUT_NUM; i++)begin : Acq_Input_SyncFifo
            axis_data_fifo_0 acqInDataFifo(
                .s_axis_aresetn(s_axi_data.reset_n & ~rst & ~acqCardSwRst & ~acqCardFifoRst),
                .s_axis_aclk(core_clk),
                .s_axis_tvalid(acqInData_DoutValid[i]),
                .s_axis_tready(acqInData_DoutReady[i]),
                .s_axis_tdata(acqInData_Dout[i]),
                .m_axis_aclk(s_axi_data.clk),
                .m_axis_tvalid(fifo2AxiDinValid[i]),
                .m_axis_tready(fifo2AxiDinReady[i]),
                .m_axis_tdata(fifo2AxiDin[i]),
                .axis_wr_data_count(acqInDataFifo_wrCount[i]),
                .axis_rd_data_count(acqInDataFifo_rdCount[i])
            );
        end

        for(i = 0; i < DAC_OUTPUT_NUM; i++)begin : Acq_Output_SyncFifo
            axis_data_fifo_0 acqOutdataSyncFifo(
                .s_axis_aresetn(s_axi_data.reset_n & ~rst & ~acqCardSwRst & ~acqCardFifoRst),
                .s_axis_aclk(core_clk),
                .s_axis_tvalid(acqOutData_DoutValid[i]),
                .s_axis_tready(acqOutData_DoutReady[i]),
                .s_axis_tdata(acqOutData_Dout[i]),
                .m_axis_aclk(s_axi_data.clk),
                .m_axis_tvalid(fifo2AxiDinValid[i + ADC_INPUT_NUM]),
                .m_axis_tready(fifo2AxiDinReady[i + ADC_INPUT_NUM]),
                .m_axis_tdata(fifo2AxiDin[i + ADC_INPUT_NUM]),
                .axis_wr_data_count(acqOutDataFifo_wrCount[i]),
                .axis_rd_data_count(acqOutDataFifo_rdCount[i])
            );
        end
 
         for(i = 0; i < DAC_OUTPUT_NUM; i++)begin : Axi_Output_SyncFifo
            axis_data_fifo_0 axiOutDataSyncFifo(
                .s_axis_aresetn(s_axi_data.reset_n & ~rst & ~acqCardSwRst & ~acqCardFifoRst),
                .s_axis_aclk(s_axi_data.clk),
                .s_axis_tvalid(fifo2AxiDoutValid[i]),
                .s_axis_tready(fifo2AxiDoutReady[i]),
                .s_axis_tdata(fifo2AxiDout[i]),
                .m_axis_aclk(core_clk),
                .m_axis_tvalid(axiOutData_DinValid_ctred[i]),
                .m_axis_tready(axiOutData_DinReady_ctred[i]),
                .m_axis_tdata(axiOutData_Din[i]),
                .axis_wr_data_count(axiOutDataFifo_wrCount[i]),
                .axis_rd_data_count(axiOutDataFifo_rdCount[i])
                
            );
        end     
        
         for(i = 0; i < DO_CTRL_REG_NUM; i++)begin : DigtalIO_Output_SyncFifo
            axis_data_fifo_0 axiOutDataSyncFifo(
                .s_axis_aresetn(s_axi_data.reset_n & ~rst & ~acqCardSwRst & ~acqCardFifoRst),
                .s_axis_aclk(s_axi_data.clk),
                .s_axis_tvalid(fifo2AxiDoutValid[i + DAC_OUTPUT_NUM]),
                .s_axis_tready(fifo2AxiDoutReady[i + DAC_OUTPUT_NUM]),
                .s_axis_tdata(fifo2AxiDout[i + DAC_OUTPUT_NUM]),
                .m_axis_aclk(core_clk),
                .m_axis_tvalid(dofifoData_DinValid_ctred[i]),
                .m_axis_tready(dofifoData_DinReady_ctred[i]),
                .m_axis_tdata(dofifoData_Din[i]),
                .axis_wr_data_count(dofifo_wrCount[i]),
                .axis_rd_data_count(dofifo_rdcount[i])
                
            );
        end 
        
    endgenerate

`endif
//    fifo2AxiFullSlave        
//    #(
//        .BASE_ADDR(AXI_DATA_BASEADDR),
//        .FIFO_DW(ACQ_CARD_DATA_DW),
//        .FIFO_NUMS(ADC_INPUT_NUM + DAC_OUTPUT_NUM)
//    )fifo2AxiData(
//        .s_axi_fifo(s_axi_data),

//        .fifoDin(fifo2AxiDin),
//        .fifoDinValid(fifo2AxiDinValid),
//        .fifoDinReady(fifo2AxiDinReady)
//    );


//    always_comb begin : Acq_Card_State
//        inFifoFull = |(~acqInData_DoutReady);
//        outFifoFull = |(~acqOutData_DoutReady);

//        inFifoThreshold = acqCardCtrl[1][$clog2(ACQ_INPUT_FIFO_DEPTH) : 0];
//        outFifoThreshold = acqCardCtrl[2][$clog2(ACQ_OUTPUT_FIFO_DEPTH) : 0];

//        interruptEnable = acqCardCtrl[3][1 : 0];//del

//        inFifoAlmostFull = inFifoDataCount[0] > inFifoThreshold;
//        outFifoAlmostFull = outFifoDataCount[0] > outFifoThreshold;

//        acqState = '0;
//        acqState[0][0] = acq_inputSyncFifo_full;
//        acqState[0][1] = acq_outputSyncFifo_full;
//        acqState[0][2] = inFifoFull;
//        acqState[0][3] = outFifoFull;
//        acqState[0][4] = inFifoAlmostFull;
//        acqState[0][5] = outFifoAlmostFull;
        
//        for(int i = 0; i < ADC_INPUT_NUM; i++)begin
//            acqState[1 + i]= acqInDataFifo_wrCount[i] - acqInDataFifo_rdCount[i];
//        end
//        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
//            acqState[1 + i + ADC_INPUT_NUM]= acqOutDataFifo_wrCount[i] - acqOutDataFifo_rdCount[i];
//        end
//        for(int i = 0; i < DAC_OUTPUT_NUM; i++)begin
//            acqState[1 + i + ADC_INPUT_NUM + DAC_OUTPUT_NUM]= axiOutDataFifo_wrCount[i] - axiOutDataFifo_rdCount[i];
//        end
//    end

//    always_ff@(posedge s_axi_lite_ctrl.clk or negedge s_axi_lite_ctrl.reset_n)begin
//        if(~s_axi_lite_ctrl.reset_n)begin
//            interrupt <= '0;
//        end
//        else begin
//            interrupt <= |(interruptEnable & {outFifoAlmostFull, outFifoAlmostFull});
//        end
//    end

    fifo2AxiFullSlave        
    #(
        .BASE_ADDR(AXI_DATA_BASEADDR),
        .FIFO_DW(ACQ_CARD_DATA_DW),
 	    .READ_FIFO_NUMS(ADC_INPUT_NUM + DAC_OUTPUT_NUM),
        .WRITE_FIFO_NUMS(DAC_OUTPUT_NUM + DO_CTRL_REG_NUM)
    )fifo2AxiData(
        .s_axi_fifo(s_axi_data),

        .fifoDin(fifo2AxiDin),
        .fifoDinValid(fifo2AxiDinValid),
        .fifoDinReady(fifo2AxiDinReady),
        
	    .fifoDout(fifo2AxiDout),
	    .fifoDoutValid(fifo2AxiDoutValid),
	    .fifoDoutReady(fifo2AxiDoutReady)
    );

endmodule

