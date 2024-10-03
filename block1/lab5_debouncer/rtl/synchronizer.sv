module synchronizer(
   input        clk,
   input        signal,
   output logic signal_sync
);

logic [1:0] sync = '1;

always_ff @( posedge clk )
   sync <= { sync[0], signal };

assign signal_sync = sync[1];

endmodule