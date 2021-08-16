
`ifndef NPS6_MACROS
`define NPS6_MACROS
  `ifndef VERBOSITY_ENUM_NPS6
    `define VERBOSITY_ENUM_NPS6
//    typedef enum {LOW,FULL,DBG} verbosity_t;
//    parameter verbosity_t VERBOSITY=DBG;
  `endif

`define PRINT_NPS6(ifdef_msg,msg,verbosity_l) \
  if (ifdef_msg ) \
  $display("%m: @%0t ",$time,msg); \
  //if(VERBOSITY>=verbosity_l) $display("%m: @%0t ",$time,msg); \
  else \
    begin end \
 
`define PRINT_NPS6_MODEL(ifdef_msg,msg,verbosity_l) \
  if (ifdef_msg ) \
  $display("%m: @%0t ",$time,msg); \
  //if(VERBOSITY>=verbosity_l) $display("%m: @%0t ",$time,msg); \

`endif 
