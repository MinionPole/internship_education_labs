vlib work

vlog -sv ../rtl/serializator.sv
vlog -sv serilializator_tb1.sv

vsim -novopt serilializator_tb1

add log -r /*
add wave /serilializator_tb1/clk
add wave /serilializator_tb1/reset
add wave /serilializator_tb1/data_i
add wave /serilializator_tb1/data_mod_i
add wave /serilializator_tb1/data_valid
add wave /serilializator_tb1/ser_data_o
add wave /serilializator_tb1/ser_data_val_o
add wave /serilializator_tb1/busy_ota_o
run -all
