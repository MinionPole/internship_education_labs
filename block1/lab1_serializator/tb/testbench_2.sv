`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.08.2024 19:41:54
// Design Name: 
// Module Name: testbench_2
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


module testbench_2;
  
  bit clk;
  bit reset;
  
  logic[15:0] data_i;
  logic[3:0] data_mod_i;
  logic data_valid; 
  
  logic ser_data_o; 
  logic ser_data_val_o; 
  logic busy_ota_o; 
  
  logic task_res_flag;
  logic how_many_data;
  int i;

  
  serializator ser_obj(
      .clk_i(clk),
      .srst_i(reset),
      
      .data_i(data_i),
      .data_mod_i(data_mod_i),
      .data_val_i(data_valid),
      
      .ser_data_o(ser_data_o),
      .ser_data_val_o(ser_data_val_o),
      .busy_o(busy_ota_o)
      );
      
  task correct_data_check(
  input reset_t,
  input         [15:0] data_i_t,
  input         [3:0]  data_mod_i_t,
  input                data_val_i_t,
  
  output  logic        res_flag_t
  );
    begin
    
     reset         <= reset_t;
     data_i        <= data_i_t;
     data_mod_i    <= data_mod_i_t;
     data_valid    <= data_val_i_t;
     res_flag_t    <= 1'b0;
     how_many_data <= (data_mod_i_t == 0) ? 4'd16 : data_mod_i_t;
     @(posedge clk)
     @(posedge clk)
     
      for(i = 0;i < how_many_data;i = i + 1)
      begin
          @(posedge clk)
          if(ser_data_o != data_i[15-i])
          begin
              $display("error, wrong data out on first cycle in %d el, need = %b, get = %b", i, data_i[15-i], ser_data_val_o);
              res_flag_t <= 1'b1;
          end
          
          if(busy_ota_o != 1)
          begin
              $display("error, must be busy on first cycle in %d el", i);
              res_flag_t <= 1'b1;
          end
          
          if(ser_data_val_o != 1)
          begin
              $display("error, must be correct data_flag on first cycle in %d el", i);
              res_flag_t <= 1'b1;
          end
      end     
     
     data_valid <= 1'b0;
    end
  endtask
  
  
  task wrong_data_check_task(
  input reset_t,
  input         [15:0] data_i_t,
  input         [3:0]  data_mod_i_t,
  input                data_val_i_t,
  
  output  logic        res_flag_t
  );
    begin    
       reset         <= reset_t;
       data_i        <= data_i_t;
       data_mod_i    <= data_mod_i_t;
       data_valid    <= data_val_i_t;
       res_flag_t    <= 1'b0;
       how_many_data <= (data_mod_i_t == 0) ? 4'd16 : data_mod_i_t;
       @(posedge clk)
       
       if(busy_ota_o == 1)
         begin
           $display("error, mustn't be busy ");
           res_flag_t <= 1'b1;
         end
         
       data_valid <= 1'b0;
     end
  endtask

      
  initial 
    forever
      #5 clk = !clk;
      
  initial
    begin
     reset <= 1;

     @(posedge clk)
     reset <= 0;
     
     @(posedge clk)
     $display("first data test start");
     correct_data_check(1'b0, 16'b1011000000000000, 4'd6, 1'b1, task_res_flag);
     if( task_res_flag )
        $display("first data test wrong");
     else
        $display("first data test ok");
     
     
     
     @(posedge clk)
     @(posedge clk)
     $display("second data test start");
     correct_data_check(1'b0, 16'b1011000000000101, 4'd0, 1'b1, task_res_flag);
     if( task_res_flag )
        $display("second data test wrong");
     else
        $display("second data test ok");
        
        
     @(posedge clk)
     @(posedge clk)
     $display("first wrong input test start");
     wrong_data_check_task(1'b0, 16'b1011000000000101, 4'd1, 1'b1, task_res_flag);
     if( task_res_flag )
        $display("first wrong input test wrong");
     else
        $display("first wrong input test ok");
        
     @(posedge clk)
     @(posedge clk)
     $display("second wrong input test start");
     wrong_data_check_task(1'b0, 16'b1011000000000101, 4'd2, 1'b1, task_res_flag);
     if( task_res_flag )
        $display("second wrong input test wrong");
     else
        $display("second wrong input test ok");         
      
    end
  
endmodule
