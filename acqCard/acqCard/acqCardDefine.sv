/*
 * @Author: ZivFung 
 * @Date: 2020-11-30 16:18:41 
 * @Last Modified by: ZivFung
 * @Last Modified time: 2020-12-04 20:30:48
 */


`ifndef _ACQCARD_DEFINE_SV_
`define _ACQCARD_DEFINE_SV_



package AcqCard;
`define VIVADO
//`define MODELSIM

    parameter ACQ_CARD_CTRL_REG_DW = 32;
    parameter ACQ_CARD_DATA_DW = 32;
    parameter COMPUTE_UNIT_FW = 23;
    parameter PID_UNIT_PARAM_NUM = 6;


    parameter ADC_INPUT_NUM = 9;
    parameter COMPUTE_UNIT_NUM = 28;
    parameter COMPUTE_UNIT_PID_NUM = 4;
    parameter DAC_OUTPUT_NUM = 12;
    parameter DO_NUM = 12;

    parameter COMPUTE_UNIT_SUM = COMPUTE_UNIT_NUM + COMPUTE_UNIT_PID_NUM;

    parameter SELMAT_SEL_WIDTH = 8;
    // parameter INPUT_SELMAT_M = ADC_INPUT_NUM + COMPUTE_UNIT_SUM + COMPUTE_UNIT_SUM;     //including const input
    parameter INPUT_SELMAT_M = ADC_INPUT_NUM + COMPUTE_UNIT_SUM;                          //Not including const input
    parameter INPUT_SELMAT_N = COMPUTE_UNIT_SUM * 2;

    parameter COMPUTE_UNIT_DELAY = 1;
    parameter CTRL_REG_SYNC_STG = 2;
    parameter OUTPUT_SELMAT_M = COMPUTE_UNIT_SUM + ADC_INPUT_NUM + DAC_OUTPUT_NUM;
    parameter OUTPUT_SELMAT_N = DAC_OUTPUT_NUM;

    parameter ACQ_INPUT_FIFO_DEPTH = 8192;
    parameter ACQ_OUTPUT_FIFO_DEPTH = 8192;

    parameter ACQ_INPUT_SYNC_FIFO_DEPTH = 2;
    parameter ACQ_OUTPUT_SYNC_FIFO_DEPTH = 2;

    parameter ACQ_CARD_CTRL_REG_NUM = 5;
    parameter INPUT_SELMAT_SEL_REG_NUM = INPUT_SELMAT_N;
    parameter OUTPUT_SELMAT_SEL_REG_NUM = OUTPUT_SELMAT_N;
    parameter COMPUTE_UNIT_FUNC_SEL_REG_NUM = COMPUTE_UNIT_SUM;
    parameter COMPUTE_UNIT_MUL_SCALE_REG_NUM = COMPUTE_UNIT_SUM;
    parameter COMPUTE_UNIT_MUL_PID_REG_NUM = COMPUTE_UNIT_PID_NUM * PID_UNIT_PARAM_NUM;
    parameter COMPUTE_UNIT_CONST_IN_REG_NUM =  COMPUTE_UNIT_SUM;
    parameter DO_CTRL_REG_NUM = 1 ;//integer'($ceil(real'(DO_NUM) / 32));
    parameter ADC_INZ_SWITCH_REG_NUM = 1 ;//integer'($ceil(real'(ADC_INPUT_NUM) / 32));
    parameter DAC_OUFIL_SWITCH_REG_NUM = 1 ;//integer'($ceil(real'(DAC_OUTPUT_NUM) / 32));

    // parameter ACQ_CARD_REG_REAL_NUM =
    //                                         ACQ_CARD_CTRL_REG_NUM +  
    //                                         INPUT_SELMAT_SEL_REG_NUM + 
    //                                         OUTPUT_SELMAT_SEL_REG_NUM + 
    //                                         COMPUTE_UNIT_FUNC_SEL_REG_NUM +
    //                                         COMPUTE_UNIT_MUL_SCALE_REG_NUM + 
    //                                         COMPUTE_UNIT_MUL_PID_REG_NUM + 
    //                                         COMPUTE_UNIT_CONST_IN_REG_NUM + 
    //                                         DO_CTRL_REG_NUM;
    // parameter ACQ_CARD_REG_NUM_W = $clog2(  
    //                                         ACQ_CARD_CTRL_REG_NUM +  
    //                                         INPUT_SELMAT_SEL_REG_NUM + 
    //                                         OUTPUT_SELMAT_SEL_REG_NUM + 
    //                                         COMPUTE_UNIT_FUNC_SEL_REG_NUM +
    //                                         COMPUTE_UNIT_MUL_SCALE_REG_NUM + 
    //                                         COMPUTE_UNIT_MUL_PID_REG_NUM + 
    //                                         COMPUTE_UNIT_CONST_IN_REG_NUM + 
    //                                         DO_CTRL_REG_NUM
    //                                 );
    // parameter ACQ_CARD_REG_NUM = 2 ** ACQ_CARD_REG_NUM_W;

    parameter ACQ_CARD_REG_REAL_NUM =
                                            ACQ_CARD_CTRL_REG_NUM +  
                                            INPUT_SELMAT_SEL_REG_NUM + 
                                            OUTPUT_SELMAT_SEL_REG_NUM + 
                                            COMPUTE_UNIT_FUNC_SEL_REG_NUM +
                                            COMPUTE_UNIT_MUL_PID_REG_NUM + 
                                            COMPUTE_UNIT_CONST_IN_REG_NUM + 
                                            DAC_OUFIL_SWITCH_REG_NUM + 
                                            ADC_INZ_SWITCH_REG_NUM;
                                            //DAC_OUFIL_SWITCH_REG_NUM
    parameter ACQ_CARD_REG_NUM_W = $clog2(  
                                            ACQ_CARD_CTRL_REG_NUM +  
                                            INPUT_SELMAT_SEL_REG_NUM + 
                                            OUTPUT_SELMAT_SEL_REG_NUM + 
                                            COMPUTE_UNIT_FUNC_SEL_REG_NUM +
                                            COMPUTE_UNIT_MUL_PID_REG_NUM + 
                                            COMPUTE_UNIT_CONST_IN_REG_NUM + 
                                            DAC_OUFIL_SWITCH_REG_NUM + 
                                            ADC_INZ_SWITCH_REG_NUM
                                            //DAC_OUFIL_SWITCH_REG_NUM
                                    );
    parameter ACQ_CARD_REG_NUM = 2 ** ACQ_CARD_REG_NUM_W;
    
    
    parameter ST_REG_NUM = 1 + ADC_INPUT_NUM + DAC_OUTPUT_NUM + DAC_OUTPUT_NUM + 1;
    parameter ST_REG_NUM_W = $clog2(ST_REG_NUM);
    parameter MEM_AW = $clog2(ST_REG_NUM + ACQ_CARD_REG_NUM);

    typedef enum logic [3 : 0]{
        ADD     = 4'b0000,
        SUB     = 4'b0001,
        MUL     = 4'b0010,
        DIV     = 4'b0011,
        ADD_C   = 4'b0100,
        SUB_C   = 4'b0101,
        MUL_C   = 4'b0110,
        DIV_C   = 4'b0111,
        PID     = 4'b1000
    } coComputeUnitFunc_t;


    function automatic logic [0 : 0] isConstCompute(coComputeUnitFunc_t func);
        return (func == ADD_C | 
                func == SUB_C | 
                func == MUL_C | 
                func == DIV_C);
    endfunction

endpackage


`endif