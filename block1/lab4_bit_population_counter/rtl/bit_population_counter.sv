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

  localparam REAL_LENGTH = 1 << ($clog2(WIDTH));
  localparam MID_VAL = REAL_LENGTH / 2;
  localparam WIDTH_MID_VAL = WIDTH / 2;
  
  logic [1:0][$clog2(MID_VAL):0]              inner_module_data_outs;
  logic [1:0]                                 inner_module_valid_data_outs;

  initial
    begin
      inner_module_data_outs[0] <= 'x; 
      inner_module_data_outs[1] <= 'x; 

      inner_module_valid_data_outs <= 'x; 
    end

  generate
    begin
      if(WIDTH != 1)
        begin
          bit_population_counter#(MID_VAL) counter_obj1(
            .clk_i(clk_i),
            .srst_i(srst_i),
            .data_i({{(MID_VAL - WIDTH_MID_VAL){1'b0}}, data_i[WIDTH_MID_VAL - 1:0]}),
            .data_val_i(data_val_i),
            .data_o(inner_module_data_outs[0]),
            .data_val_o(inner_module_valid_data_outs[0])
          );

          if(WIDTH % 2 == 0)
            bit_population_counter#(MID_VAL) counter_obj2(
              .clk_i(clk_i),
              .srst_i(srst_i),
              .data_i({{(MID_VAL - WIDTH_MID_VAL){1'b0}}, data_i[WIDTH_MID_VAL * 2 - 1: WIDTH_MID_VAL]}),
              .data_val_i(data_val_i),
              .data_o(inner_module_data_outs[1]),
              .data_val_o(inner_module_valid_data_outs[1])
            );
          else
            bit_population_counter#(MID_VAL) counter_obj2(
              .clk_i(clk_i),
              .srst_i(srst_i),
              .data_i({{(MID_VAL - WIDTH_MID_VAL - 1){1'b0}}, data_i[WIDTH_MID_VAL * 2: WIDTH_MID_VAL]}),
              .data_val_i(data_val_i),
              .data_o(inner_module_data_outs[1]),
              .data_val_o(inner_module_valid_data_outs[1])
            );                         
        end
    end
  endgenerate

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
            if(inner_module_valid_data_outs[0] && inner_module_valid_data_outs[1])
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
            if(inner_module_valid_data_outs[0] && inner_module_valid_data_outs[1])
              data_o <= (inner_module_data_outs[0] + inner_module_data_outs[1]);
            else
              data_o <= '0;
          end
    end

endmodule