vlib work


vlog -sv ../rtl/fifo.sv
vlog -sv fifo_tb.sv

proc runtest {i j} {
  vsim -L altera_mf -novopt fifo_tb
  add log -r /*
  add wave /fifo_tb/clk
  add wave /fifo_tb/data_i
  add wave /fifo_tb/wrreq_i
  add wave /fifo_tb/rdreq_i
  add wave /fifo_tb/q_o1
  add wave /fifo_tb/q_o2
  run -all
}

runtest 200 10000