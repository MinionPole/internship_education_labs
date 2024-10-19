vlib work

vlog -sv ../rtl/traffic_lights.sv
vlog -sv traffic_lighs_tb.sv

proc runtest {i j} {
  vsim -novopt traffic_lighs_tb
  add log -r /*
  add wave /traffic_lighs_tb/clk
  add wave /traffic_lighs_tb/srst
  add wave /traffic_lighs_tb/cmd_type_i
  add wave /traffic_lighs_tb/cmd_valid_i  
  add wave /traffic_lighs_tb/red_o
  add wave /traffic_lighs_tb/yellow_o
  add wave /traffic_lighs_tb/green_o
  add wave /traffic_lighs_tb/prev_state
  add wave /traffic_lighs_tb/now_state
  run -all
}

runtest 200 10000