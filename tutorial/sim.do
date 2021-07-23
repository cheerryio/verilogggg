set UVM_DPI_HOME C:/modeltech64_10.6e/uvm-1.2/win64
vlib work
vlog -work work -quiet +incdir+C:/modeltech64_10.6e/uvm-1.1d/../verilog_src/uvm-1.1d/src *.sv
vsim -c -quiet -sv_lib $UVM_DPI_HOME/uvm_dpi work.mul_tb;
run 1000