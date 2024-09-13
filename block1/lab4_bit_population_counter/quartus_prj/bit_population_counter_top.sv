module bit_population_counter_top#(
  parameter WIDTH = 128
)(
  input                         clk_150mhz,
  input                         srst_i,
  input  [(WIDTH-1):0]          data_i,
  input                         data_val_i,

  output [$clog2(WIDTH):0]  data_o,
  output                        data_val_o
);
  logic                         srst_i_reg;
  logic  [(WIDTH-1):0]          data_i_reg;
  logic                         data_val_i_reg;

  logic [$clog2(WIDTH):0]  data_o_reg;
  logic                        data_val_o_reg;

  always_ff @(posedge clk_150mhz)
    begin
      srst_i_reg           <= srst_i;
      data_i_reg           <= data_i;
      data_val_i_reg       <= data_val_i;
		
      data_o               <= data_o_reg;
      data_val_o           <= data_val_o_reg;
    end

  bit_population_counter#(WIDTH) priority_encoder_obj(
    .clk_i(clk_150mhz),
    .srst_i(srst_i_reg),
    .data_i(data_i_reg),
    .data_val_i(data_val_i_reg),

    .data_o(data_o_reg),
    .data_val_o(data_val_o_reg)
  );

endmodule