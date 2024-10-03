vlib work

vlog -sv ../rtl/debouncer.sv
vlog -sv debouncer_tb.sv

proc runtest {i j} {
  vsim -novopt -gCLK_FREQ_MHZ=$i -gGLITCH_TIME_NS=$j debouncer_tb
  add log -r /*
  add wave /debouncer_tb/clk
  add wave /debouncer_tb/key
  add wave /debouncer_tb/key_pressed_stb
  add wave /debouncer_tb/debouncer_obj/cnt
  add wave /debouncer_tb/debouncer_obj/sync_out
  run -all
}
for {set i 10} {$i <= 500} {incr i 50} {
  for {set j 1} {$j <= 50} {incr j 10} {
    runtest $i $j
  }
}

