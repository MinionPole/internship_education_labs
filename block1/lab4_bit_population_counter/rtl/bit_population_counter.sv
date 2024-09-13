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

logic [WIDTH-1:0][$clog2(WIDTH):0] cnt_low_level;
logic [$clog2(LOWLEVELSIZE):0][WIDTH-1:0][$clog2(WIDTH):0] cnt;
logic [$clog2(LOWLEVELSIZE):0][$clog2(LOWLEVELSIZE):0] level_sizes;


initial
  begin
    level_sizes[0] = LOWLEVELSIZE;
    for(int top_level_ind = 1; top_level_ind <= $clog2(LOWLEVELSIZE);top_level_ind++)
	    begin
        level_sizes[top_level_ind] = (level_sizes[top_level_ind - 1] + 1) / 2;
		    //$display("top_level_ind = %d, value is = %d", top_level_ind, level_sizes[top_level_ind]);
		  end
  end

always_ff @( posedge clk_i )
  begin
	 for(int top_level_ind = 1; top_level_ind <= $clog2(LOWLEVELSIZE);top_level_ind++)
	   begin
		  for(int i = 0; i < level_sizes[top_level_ind];i++)
		    begin
            if(i * 2 + 1 < level_sizes[top_level_ind - 1])
              cnt[top_level_ind][i] <= cnt[top_level_ind - 1][i * 2 + 1] + cnt[top_level_ind - 1][i * 2];
            else
              cnt[top_level_ind][i] <= cnt[top_level_ind - 1][i * 2];
			 end
		end
  end


always_ff @( posedge clk_i )
  begin
    cnt[0] <= cnt_low_level;
  end

always_comb
  begin
    for(int i = 0; i < LOWLEVELSIZE;i++)
	  begin
		  cnt_low_level[i] = '0;
	    for(int j = 0; j < SLICE && i * SLICE + j < WIDTH;j++)
		    cnt_low_level[i] = cnt_low_level[i] + data_i[i * SLICE + j];
      //$display("i = %d val = %b", i, cnt_low_level[i]);
		end
  end

always_ff @( posedge clk_i )
  data_o <= cnt[$clog2(LOWLEVELSIZE)][0];

logic [$clog2(LOWLEVELSIZE)+1:0] valid_delay;

always_ff @(posedge clk_i)
  if( srst_i )
    valid_delay <= '0;
  else
    valid_delay <= {valid_delay[$clog2(LOWLEVELSIZE):0],data_val_i};

assign data_val_o = valid_delay[$clog2(LOWLEVELSIZE)+1];

endmodule