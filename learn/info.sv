
//  Choosing the correct data type

//  The following provides some guidance in choosing the proper data type. The first thing to understand is
//  if all tools that will use this code (synthesis, simulator, linters, etc.) is SystemVerilog
//  compliant or needs Verilog-2001 constructs.  If SystemVerilog is available, it is suggested to move to
//  the newer constructs when possible.  Also it should be early established if using signed or unsigned
//  types.  If the desired code is using signed arithmetic, particularly when targeting the DSP48 multiplication,
//  signed data types are generally preferred where in most all other cases, unsigned is easier and preferred.

//  If declaring a signal in which will connect to an output of an instantiated component, use the wire type:

//  Signed:
wire signed [31:0] data_bus;
// Unsigned:
wire [31:0] data_bus;

//  If declaring a signal that will infer a register, latch, SRL or memory using an always block, use an
//  initialized reg type:

//  Signed:
reg signed [15:0] my_reg = 16'shffff;
// Unsigned:
reg [15:0] my_reg = 16'hffff;

//  Xilinx highly suggests to initialize all inferred registers and memories as it is fully synthesizable
//  and makes RTL simulation results more closely match hardware programming.

//  If declaring a signal that is used in a combinatorial always block, for SystemVerilog it is suggested
//  to use the logic data type:

logic unregistered_logic_sig;

//  If using Verilog-2001, select an uninitialized reg data type:

reg unregistered_logic_sig;

//  It is not suggested to initialize signals that will not become a register or memory as that is generally
//  not synthesizable.  In terms of the SystemVerilog logic type vs. the Verilog-2001 reg type, the two are
//  equivalent in terms of behavior however the logic type better communicates the intent it will later become
//  logic rather than a register.

//  If declaring a variable like an integer for a for loop, for SystemVerilog, the int type can be used:

int i;

//  or for Verilog-2001, the integer type:

integer i;

//  The SystemVerilog int type is equivalent to the Verilog-2001 integer type.

//  SystemVerilog allows the declaration of enumerated types.  These are useful in defining state-machines or
//  other processing code without implicitly defining regster encoding.  This also makes such code more readable
//  and easier to debug.  An example of this is as follows:

enum {RESET, FIND_FIRST_PATTERN, FIND_SECOND_PATTERN, REACT, START_OVER} state_machine;

//  In order to define a constant in the code that is intended to be overridden by the module that instantiates it, use a parameter:

parameter WIDTH = 8;

//  To define a constant that will not be overridden, use localparam:

localparam Pi = 3.14159265;

//  For more information on parameters, refer to the Info section of the Parameter folder.
			
			