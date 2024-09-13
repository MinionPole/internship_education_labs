module bit_population_counter #(
  parameter WIDTH = 128,
  parameter SLICE = 6
)(
  input                               clk_i,
  input                               srst_i,
  input        [(WIDTH-1):0]          data_i,
  input                               data_val_i,

  output logic [$clog2(WIDTH):0]      data_o,
  output logic                        data_val_o
);

localparam LOWLEVELSIZE = (WIDTH + SLICE - 1) / SLICE;

logic [$clog2(LOWLEVELSIZE):0][LOWLEVELSIZE - 1:0][$clog2(WIDTH):0] cnt;


int level_size;
always_comb
  begin
   level_size = LOWLEVELSIZE;
	 for(int i = 0; i < LOWLEVELSIZE;i++)
	  begin
		 cnt[0][i] = '0;
	    for(int j = 0; j < SLICE && i * SLICE + j < WIDTH;j++)
		    cnt[0][i] += data_i[i * SLICE + j];
     $display("i = %d val = %b", i, cnt[0][i]);
		end

		 
	 for(int top_level_ind = 1; top_level_ind <= $clog2(LOWLEVELSIZE);top_level_ind++)
	   begin
		  for(int i = 0; i < (level_size + 1) / 2;i++)
		    begin
				  cnt[top_level_ind][i] = cnt[top_level_ind - 1][i * 2];
          if(i * 2 + 1 < level_size)
            cnt[top_level_ind][i] += cnt[top_level_ind - 1][i * 2 + 1];
          $display("i = %d, j = %d, val = %b", top_level_ind, i, cnt[top_level_ind][i]);
			  end
      level_size = (level_size + 1) / 2;
		end
  end

always_ff @( posedge clk_i )
  data_o <= cnt[$clog2(LOWLEVELSIZE)][0];

always_ff @( posedge clk_i )
  if( srst_i )
    data_val_o <= 1'b0;
  else
    data_val_o <= data_val_i;

endmodule