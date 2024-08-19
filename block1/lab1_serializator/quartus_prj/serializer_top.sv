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


module serializer_top(
    input          clk_150mhz,
    input          srst_i,

    input  [15:0]  data_i,
    input  [3:0]   data_mod_i,
    input          data_val_i,

    output         ser_data_o,
    output         ser_data_val_o,
    output         busy_o
);

  serializer ser_obj(
      .clk_i(clk_150mhz),
      .srst_i(srst_i),

      .data_i(data_i),
      .data_mod_i(data_mod_i),
      .data_val_i(data_val_i),

      .ser_data_o(ser_data_o),
      .ser_data_val_o(ser_data_val_o),
      .busy_o(busy_o)
   );	
endmodule
