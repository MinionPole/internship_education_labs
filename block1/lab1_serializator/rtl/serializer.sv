module serializer(
  input        clk_i,
  input        srst_i,

  input [15:0] data_i,
  input [3:0]  data_mod_i,
  input        data_val_i,

  output       ser_data_o,
  output       ser_data_val_o,

  output       busy_o
);

logic [4:0] real_mod;
logic [4:0] cnt;
logic [15:0] data;
logic [4:0] not_cnt;

always_comb
  begin
  not_cnt = (cnt != 0);
  end

always_comb
  begin
    real_mod = data_mod_i;
    case( data_mod_i )
      0   : real_mod = 16;
      1,2 : real_mod = 0;
    endcase
  end

always_ff @( posedge clk_i )
  if( srst_i )
    cnt <= '0;
  else
    if( data_val_i && !busy_o )
      cnt <= real_mod;
    else
      if( cnt != '0 )
        cnt <= cnt - 1;

always_ff @( posedge clk_i )
  if( data_val_i && !busy_o )
    data <= data_i;
  else
    data <= data << 1;

assign ser_data_o     = data[15];
assign ser_data_val_o = not_cnt;
assign busy_o         = ser_data_val_o;

endmodule