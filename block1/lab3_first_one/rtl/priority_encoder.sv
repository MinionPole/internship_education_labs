module priority_encoder #(
  parameter WIDTH = 3
)(
  input                       clk_i,
  input                       srst_i,
  input        [(WIDTH-1):0]  data_i,
  input                       data_val_i,

  output logic [(WIDTH-1):0]  data_left_o,
  output logic [(WIDTH-1):0]  data_right_o,
  output logic                data_val_o
);
  
  logic[$clog2(WIDTH) + 1:0] left_o_ind;
  logic[$clog2(WIDTH) + 1:0] right_o_ind;
  always_comb
    begin
      logic[$clog2(WIDTH) + 1:0] i;
      right_o_ind = WIDTH;
      for(i = WIDTH - 1; i >= 0 && i < WIDTH;i--)
        if(data_i[i] == 1)
          right_o_ind = i;
    end

  always_comb
    begin
      logic[$clog2(WIDTH) + 1:0] i;
      left_o_ind = WIDTH;
      for(i = 0; i < WIDTH;i++)
        if(data_i[i] == 1)
          left_o_ind = i;
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        data_right_o <= 0;
      else
        if(data_val_i)
          begin
            data_right_o <= '0;
            if(right_o_ind != WIDTH)
              data_right_o[right_o_ind] <= 1'b1;
          end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        data_left_o <= 0;
      else
        if(data_val_i)
          begin
            data_left_o <= 0;
            if(left_o_ind != WIDTH)
              data_left_o[left_o_ind] <= 1;
          end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        data_val_o <= 0;
      else
        data_val_o <= (data_val_i == 1);
    end

endmodule