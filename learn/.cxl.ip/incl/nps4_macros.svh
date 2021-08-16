
`ifndef NPS4_MACROS
`define NPS4_MACROS
  `ifndef VERBOSITY_ENUM_NPS4
    `define VERBOSITY_ENUM_NPS4
//    typedef enum {LOW,FULL,DBG} verbosity_t;
//    parameter verbosity_t VERBOSITY=DBG;
  `endif

`define PRINT_NPS4(ifdef_msg,msg,verbosity_l) \
  if (ifdef_msg ) \
  $display("%m : @%0t ",$time,msg); \
//  if(VERBOSITY>=verbosity_l) $display("%m : @%0t ",$time,msg); \
  else \
    begin end \
 
`define PRINT_NPS4_MODEL(ifdef_msg,msg,verbosity_l) \
  if (ifdef_msg ) \
  $display("%m : @%0t ",$time,msg); \
// if(VERBOSITY>=verbosity_l) $display("%m : @%0t ",$time,msg); \
 
`define PRINT_NPS4_WARNING(msg) \
  $warning("%m ::: at time %0t ::: ",$time,msg); \
 
`define PRINT_NPS4_FATAL(msg) \
  $fatal(1,"%m ::: at time %0t ::: ",$time,msg); \
 
`define PRINT_NPS4_ERROR(msg) \
  $error("%m ::: at time %0t ::: ",$time,msg); \

`endif 
