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

  localparam                                          SLICE_CNT     = (WIDTH + SLICE - 1) / SLICE;
  localparam                                          LOG_SLICE_CNT = $clog2(SLICE_CNT);
  localparam logic [LOG_SLICE_CNT:0][LOG_SLICE_CNT:0] LEVEL_SIZES   = calculate_level_sizes();

  logic [WIDTH-1:0][$clog2(WIDTH):0]                  cnt_low_level;
  logic [LOG_SLICE_CNT:0][WIDTH-1:0][$clog2(WIDTH):0] cnt;


  logic [LOG_SLICE_CNT+1:0] valid_delay;
  assign data_val_o = valid_delay[LOG_SLICE_CNT+1];

  function logic [LOG_SLICE_CNT:0][LOG_SLICE_CNT:0] calculate_level_sizes();
    logic [LOG_SLICE_CNT:0][LOG_SLICE_CNT:0] sizes;
    sizes[0] = SLICE_CNT;  
    for( int top_level_ind = 1; top_level_ind <= LOG_SLICE_CNT; top_level_ind++ )
      begin
        sizes[top_level_ind] = (sizes[top_level_ind - 1] + 1) / 2;
      end
    return sizes;
  endfunction

  always_ff @( posedge clk_i )
    begin
     for( int top_level_ind = 1; top_level_ind <= LOG_SLICE_CNT; top_level_ind++ )
       begin
       for( int i = 0; i < LEVEL_SIZES[top_level_ind]; i++ )
          begin
              if( i * 2 + 1 < LEVEL_SIZES[top_level_ind - 1] )
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
      for( int i = 0; i < SLICE_CNT; i++ )
      begin
        cnt_low_level[i] = '0;
        for( int j = 0; j < SLICE && i * SLICE + j < WIDTH; j++ )
          cnt_low_level[i] = cnt_low_level[i] + data_i[i * SLICE + j];
        //$display("i = %d val = %b", i, cnt_low_level[i]);
      end
    end

  always_ff @( posedge clk_i )
    data_o <= cnt[LOG_SLICE_CNT][0];

  always_ff @( posedge clk_i )
    if( srst_i )
      valid_delay <= '0;
    else
      valid_delay <= {valid_delay[LOG_SLICE_CNT:0],data_val_i};

endmodule