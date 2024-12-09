vlib work


vlog -sv ../rtl/memory.sv
vlog -sv memory_tb.sv

proc runtest {i j} {
  vsim -L altera_mf -novopt memory_tb
  add log -r /*
  add wave /memory_tb/clk
  add wave /memory_tb/srst
  add wave /memory_tb/data_write
  add wave /memory_tb/data_write_ind
  add wave /memory_tb/wrreq
  add wave /memory_tb/data_read_ind
  add wave /memory_tb/rdreq
  add wave /memory_tb/readen_out
  run -all
}

runtest 200 10000