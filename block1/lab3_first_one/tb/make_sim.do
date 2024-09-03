vlib work

vlog -sv ../rtl/priority_encoder.sv
vlog -sv priority_encoder_tb.sv
for {set i 1} {$i <= 30} {incr i} {
  vsim -novopt -gWIDTH=$i priority_encoder_tb
  add log -r /*
  add wave /priority_encoder_tb/clk
  add wave /priority_encoder_tb/srst
  add wave /priority_encoder_tb/data
  add wave /priority_encoder_tb/data_val_i
  add wave /priority_encoder_tb/data_left
  add wave /priority_encoder_tb/data_right
  add wave /priority_encoder_tb/data_val_o
  run -all
  quit -sim
}