#!/bin/csh -f
xvlog -sv -f compile_list.f -L uvm --incr --nolog; 
xelab dut_tb -relax -s top -timescale 1ns/10ps --incr --nolog;  
xsim top --nolog --wdb wav.wdb -runall;
# -testplusarg UVM_TESTNAME=adder_4_bit_basic_test -testplusarg UVM_VERBOSITY=UVM_LOW -runall 