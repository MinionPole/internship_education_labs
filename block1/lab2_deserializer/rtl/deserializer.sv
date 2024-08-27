`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.08.2024 19:25:56
// Design Name: 
// Module Name: deserializer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module deserializer(
  input          clk_i,
  input          srst_i,
  input          data_i,
  input          data_val_i,
    
  output [15:0]  deser_data_o,
  output         deser_data_val_o
  );
  logic [15:0] deser_data_o_reg;
  assign deser_data_o = deser_data_o_reg;

  logic deser_data_val_o_reg;
  assign deser_data_val_o = deser_data_val_o_reg;

  logic [4:0] cnt;

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          cnt <= 5'd15;
        end
      else
        begin
          if(data_val_i)
            begin
              if(cnt == 0)
                cnt <= 5'd15;
              else
                cnt <= (cnt - 1'b1);
            end
        end
    end

  always_ff @(posedge clk_i)
    begin
      if(data_val_i)
        begin
          deser_data_o_reg <= {deser_data_o_reg[14:0], data_i};
        end
    end

  always_ff @(posedge clk_i)
    begin
      deser_data_val_o_reg <= (cnt == 0 );
    end

endmodule
