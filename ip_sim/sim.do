set UVM_DPI_HOME C:/modeltech64_10.6e/uvm-1.2/win64
vlib work
vlog -work work xor.sv
vsim -c -sv_lib $UVM_DPI_HOME/uvm_dpi work.xor_tb
run 100ns