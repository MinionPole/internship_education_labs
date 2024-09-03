module priority_encoder
  #(
    parameter WIDTH = 5
  )
  (
    input                       clk_i,
    input                       srst_i,
    input        [(WIDTH-1):0]  data_i,
    input                       data_val_i,

    output logic [(WIDTH-1):0]  data_left_o,
    output logic [(WIDTH-1):0]  data_right_o,
    output logic                data_val_o
  );
  logic [(WIDTH-1):0] zero_data = '0;
  int right_o_ind;
  int left_o_ind;
  always_comb
    begin
      right_o_ind = -1;
      left_o_ind = -1;
      for(int i = 0; i < WIDTH;i++)
        begin
          if(data_i[i] == 1)
            right_o_ind = i;
        end
      for(int i = WIDTH - 1; i >= 0;i--)
        begin
          if(data_i[i] == 1)
            left_o_ind = i;
        end  
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          data_right_o <= 0;
        end
      else
        begin
          if(data_val_i)
            begin
              data_right_o <= '0;
              if(right_o_ind != -1)
                data_right_o[right_o_ind] <= 1'b1;
            end
        end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          data_left_o <= 0;
        end
      else
        begin
          if(data_val_i)
            begin
              data_left_o <= 0;
              if(left_o_ind != -1)
                data_left_o[left_o_ind] <= 1;
            end
        end
    end

  always_ff @(posedge clk_i)
    begin
      data_val_o <= (data_val_i == 1);
    end
    

endmodule