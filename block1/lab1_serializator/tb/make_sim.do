vlib work

vlog -sv ../rtl/serializer.sv
vlog -sv serializer_tb.sv

vsim -novopt serializer_tb

add log -r /*
add wave /serializer_tb/clk
add wave /serializer_tb/srst
add wave /serializer_tb/data_i
add wave /serializer_tb/data_mod_i
add wave /serializer_tb/data_val_i
add wave /serializer_tb/ser_data
add wave /serializer_tb/ser_val
add wave /serializer_tb/busy
run -all
