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


module serializator_top(
    input         clk_150mhz
    );
      
  bit reset;

  logic[15:0] data_i;
  logic[3:0] data_mod_i;
  logic data_valid; 

  logic ser_data_o; 
  logic ser_data_val_o; 
  logic busy_ota_o; 


  serializator ser_obj(
      .clk_i(clk_150mhz),
      .srst_i(reset),
    
      .data_i(data_i),
      .data_mod_i(data_mod_i),
      .data_val_i(data_valid),
    
      .ser_data_o(ser_data_o),
      .ser_data_val_o(ser_data_val_o),
      .busy_o(busy_ota_o)
   );	 
	 
    
endmodule
