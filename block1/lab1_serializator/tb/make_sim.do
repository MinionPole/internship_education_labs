vlib work

vlog -sv ../rtl/serializator.sv
vlog -sv testbench_2.sv

vsim -novopt testbench_2

add log -r /*
add wave /testbench_2/clk
add wave /testbench_2/reset
add wave /testbench_2/data_i
add wave /testbench_2/data_mod_i
add wave /testbench_2/data_valid
add wave /testbench_2/ser_data_o
add wave /testbench_2/ser_data_val_o
add wave /testbench_2/busy_ota_o
run -all
