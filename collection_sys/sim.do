set UVM_DPI_HOME C:/modeltech64_10.6e/uvm-1.2/win64
vlib work
vlog -work work counter.sv collection_sys_final_sim.sv ADS1675.sv
vsim -c -sv_lib $UVM_DPI_HOME/uvm_dpi work.ADS1675_gen_sim_tb
run 100000000000