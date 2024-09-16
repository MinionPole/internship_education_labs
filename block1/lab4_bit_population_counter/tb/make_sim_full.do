vlib work

vlog -sv ../rtl/bit_population_counter.sv
vlog -sv bit_population_counter_tb.sv

proc runtest {i} {
  vsim -novopt -gWIDTH=$i bit_population_counter_tb
  add log -r /*
  add wave /bit_population_counter_tb/clk
  add wave /bit_population_counter_tb/srst
  add wave /bit_population_counter_tb/data
  add wave /bit_population_counter_tb/data_val_i
  add wave /bit_population_counter_tb/data_o
  add wave /bit_population_counter_tb/data_val_o
  run -all
  quit -sim
}

for {set i 1} {$i <= 30} {incr i} {
  runtest $i
}

runtest [50]

runtest [150]