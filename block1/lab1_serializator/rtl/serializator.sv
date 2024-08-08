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


module serializator(
    input         clk_i,
    input         srst_i,
    
    input  [15:0] data_i,
    input  [3:0]  data_mod_i,
    input         data_val_i,
    
    output        ser_data_o,
    output        ser_data_val_o,
    output        busy_o
    );
    
    logic ser_data_o_reg;
    logic ser_data_val_o_reg;
    logic busy_o_reg;
    
    assign ser_data_o     = ser_data_o_reg;
    assign ser_data_val_o = ser_data_val_o_reg;
    assign busy_o         = busy_o_reg;
    
    logic  [15:0] data_copy;    
    logic  [3:0]  now_to_write;
    logic  [3:0]  max_to_write;
    logic zero_bit_flag;
    
    always_ff @( posedge clk_i )
      begin
        if( srst_i )
          begin
          // reset
            ser_data_o_reg     <= 1'b0;
            ser_data_val_o_reg <= 1'b0;
            busy_o_reg         <= 1'b0;
            
            data_copy          <= 16'b0;   
            now_to_write       <= 4'b0;
            max_to_write       <= 4'b0;
            zero_bit_flag      <= 1'b0;
          end
        else
          begin
            if( busy_o_reg )
              begin
                // writing
                if( now_to_write < max_to_write || zero_bit_flag)
                  begin
                    ser_data_val_o_reg <= 1'b0;
                    busy_o_reg     <= 1'b0;
                    zero_bit_flag <= 1'b0;
                  end
                else
                  begin
                    ser_data_o_reg     <= data_copy[now_to_write];
                    ser_data_val_o_reg <= 1'b1;
                    if(now_to_write == 4'b0)
                      zero_bit_flag <= 1'b1;
                    else
                      now_to_write <= now_to_write - 1'b1;                    
                  end
              end
            else
              begin
              // wait in
                if( data_val_i == 1'b1 && data_mod_i != 4'b0001 && data_mod_i != 4'b0010 )
                  begin
                    busy_o_reg     <= 1'b1;
                    now_to_write   <= 4'd15;
                    data_copy      <= data_i; 
                    if( data_mod_i == 4'b0000 )
                      max_to_write <= 4'd0;
                    else
                      max_to_write <= ( 4'd15 - data_mod_i + 4'd1 );
   
                  end
              end
          end
      end
    
endmodule
