if {[file exists work]} {
    # If it exists, delete it
    file delete -force work
}

vlib work

vlog -sv ../rtl/fifo.sv
vlog -sv ../rtl/memory.sv
vlog -sv fifo_tb.sv

proc runtest {i j} {
  vsim -L altera_mf -novopt +NUM_ITERATIONS=1000 fifo_tb
  add log -r /*
  add wave /fifo_tb/clk
  add wave /fifo_tb/srst
  add wave /fifo_tb/data_i
  add wave /fifo_tb/wrreq_i
  add wave /fifo_tb/rdreq_i
  add wave /fifo_tb/q_o1
  add wave /fifo_tb/q_o2
  add wave /fifo_tb/empty_o2
  add wave /fifo_tb/empty_o1
  add wave /fifo_tb/full_o2
  add wave /fifo_tb/full_o1

  add wave /fifo_tb/usedw_o1
  add wave /fifo_tb/usedw_o2

  add wave /fifo_tb/almost_full_o1
  add wave /fifo_tb/almost_full_o2

  add wave /fifo_tb/almost_empty_o1
  add wave /fifo_tb/almost_empty_o2

  run -all
}

runtest 200 10000