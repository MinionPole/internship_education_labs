vlib work

vlog -sv ../rtl/serializer.sv
vlog -sv serializer_tb.sv

vsim -novopt serializer_tb

add log -r /*
add wave /serializer_tb/clk
add wave /serializer_tb/reset
add wave /serializer_tb/data_i
add wave /serializer_tb/data_mod_i
add wave /serializer_tb/data_valid
add wave /serializer_tb/ser_data_o
add wave /serializer_tb/ser_data_val_o
add wave /serializer_tb/busy_ota_o
run -all
