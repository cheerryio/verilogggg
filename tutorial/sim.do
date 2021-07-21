set UVM_DPI_HOME C:/modeltech64_10.6e/uvm-1.2/win64
vlib work
vlog -work work *.sv
vsim -c -sv_lib $UVM_DPI_HOME/uvm_dpi work.hello_world_example
run 100
exit