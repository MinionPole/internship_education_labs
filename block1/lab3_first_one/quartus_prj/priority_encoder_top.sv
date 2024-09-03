`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.08.2024 19:49:45
// Design Name: 
// Module Name: serializator
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


module priority_encoder_top  #(
    parameter WIDTH = 5
  )
  (
    input                       clk_150mhz,
    input                       srst_i,
    input        [(WIDTH-1):0]  data_i,
    input                       data_val_i,

    output logic [(WIDTH-1):0]  data_left_o,
    output logic [(WIDTH-1):0]  data_right_o,
    output logic                data_val_o
);
    logic                       srst_i_reg;
    logic        [(WIDTH-1):0]  data_i_reg;
    logic                       data_val_i_reg;

    logic [(WIDTH-1):0]  data_left_o_reg;
    logic [(WIDTH-1):0]  data_right_o_reg;
    logic                data_val_o_reg;

  always_ff @(posedge clk_150mhz)
    begin
      srst_i_reg           <= srst_i;
      data_i_reg           <= data_i;
      data_val_i_reg       <= data_val_i;
		
      data_left_o          <= data_left_o_reg;
      data_right_o         <= data_right_o_reg;
      data_val_o           <= data_val_o_reg;
    end
  

  priority_encoder#(WIDTH) priority_encoder_obj(
    .clk_i(clk_150mhz),
    .srst_i(srst_i_reg),
    .data_i(data_i_reg),
    .data_val_i(data_val_i_reg),

    .data_left_o(data_left_o_reg),
    .data_right_o(data_right_o_reg),
    .data_val_o(data_val_o_reg)
  );

endmodule