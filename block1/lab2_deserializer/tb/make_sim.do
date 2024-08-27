vlib work

vlog -sv ../rtl/deserializer.sv
vlog -sv deserializer_tb.sv

vsim -novopt deserializer_tb

add log -r /*
add wave /deserializer_tb/clk
add wave /deserializer_tb/srst
add wave /deserializer_tb/data
add wave /deserializer_tb/data_val
add wave /deserializer_tb/deser_data
add wave /deserializer_tb/deser_data_val
run -all
