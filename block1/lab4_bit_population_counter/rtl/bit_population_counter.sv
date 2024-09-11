module bit_population_counter #(
  parameter WIDTH = 3
)(
  input                               clk_i,
  input                               srst_i,
  input        [(WIDTH-1):0]          data_i,
  input                               data_val_i,

  output logic [$clog2(WIDTH) + 1:0]  data_o,
  output logic                        data_val_o
);

  localparam REAL_LENGTH = 1 << ($clog2(WIDTH));
  localparam MID_VAL = REAL_LENGTH / 2;

  logic [REAL_LENGTH - 1: 0] data_i_input;
  
  logic [$clog2(MID_VAL) + 1:0]          data_o_out1;
  logic                                  data_val_o_out1;
  logic [$clog2(MID_VAL) + 1:0]          data_o_out2;
  logic                                  data_val_o_out2;

  if(WIDTH != 1)
    begin
      bit_population_counter#(MID_VAL) counter_obj1( // left part of data
        .clk_i(clk_i),
        .srst_i(srst_i),
        .data_i(data_i_input[MID_VAL - 1:0]),
        .data_val_i(data_val_i),
        .data_o(data_o_out1),
        .data_val_o(data_val_o_out1)
      );

      bit_population_counter#(MID_VAL) counter_obj2(  // right part of data
        .clk_i(clk_i),
        .srst_i(srst_i),
        .data_i(data_i_input[(REAL_LENGTH-1):MID_VAL]),
        .data_val_i(data_val_i),
        .data_o(data_o_out2),
        .data_val_o(data_val_o_out2)
      );
    end

  always_comb
    begin
      data_i_input = (data_val_i == 1) ? data_i : '0;
    end

  always_ff @(posedge clk_i)
    begin
      //$display("width = %d, data = %b, data_valid = %b", WIDTH, data_i, data_val_i);
      if(srst_i)
        data_val_o <= '0;
      else
        if(WIDTH == 1)
          begin
            if(data_val_i)
              data_val_o <= 1;
            else
              data_val_o <= '0;
          end
        else
          begin
            //$display("width = %d, data_val_left = %b, data_val_right = %b", WIDTH, data_val_o_out1, data_val_o_out2);
            if(data_val_o_out1 && data_val_o_out2)
              data_val_o <= 1;
            else
              data_val_o <= '0;
          end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        data_o <= '0;
      else
        if(WIDTH == 1)
          begin
            if(data_val_i)
              data_o <= data_i;
            else
              data_o <= '0;
          end
        else
          begin
            //$display("width = %d, data_val_left = %b, data_val_right = %b", WIDTH, data_val_o_out1, data_val_o_out2);
            if(data_val_o_out1 && data_val_o_out2)
              data_o <= (data_o_out1 + data_o_out2);
            else
              data_o <= '0;
          end
    end

endmodule