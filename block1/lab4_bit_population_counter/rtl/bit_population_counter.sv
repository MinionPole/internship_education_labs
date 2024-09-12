module bit_population_counter #(
  parameter WIDTH = 63
)(
  input                               clk_i,
  input                               srst_i,
  input        [(WIDTH-1):0]          data_i,
  input                               data_val_i,

  output logic [$clog2(WIDTH):0]  data_o,
  output logic                        data_val_o
);

int cnt;
always_comb
  begin
    cnt = '0;
    for( int i = 0; i < WIDTH; i++ )
      cnt = cnt + data_i[i];
  end

always_ff @( posedge clk_i )
  if(srst_i)
    data_o <= '0;
  else
    data_o <= cnt;

always_ff @( posedge clk_i )
  if( srst_i )
    data_val_o <= 1'b0;
  else
    data_val_o <= data_val_i;

endmodule