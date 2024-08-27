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


module deserializer_top(
    input          clk_150mhz,
    input          srst,

    input  [15:0]  data,
    input          data_val,

    output         deser_data,
    output         deser_data_val
);

  deserializer deserializer_obj(
      .clk_i(clk_150mhz),
      .srst_i(srst),
      .data_i(data),
      .data_val_i(data_val),
    
      .deser_data_o(deser_data),
      .deser_data_val_o(deser_data_val)
  );
  
endmodule