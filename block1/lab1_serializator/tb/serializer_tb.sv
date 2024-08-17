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


module serializer_tb#(parameter MAX_WORK_TIMEOUT = 8, MAX_COOLDOWN_TIMEOUT = 100);

  bit clk;
  bit reset;

  logic[15:0] data_i;
  logic[3:0] data_mod_i;
  logic data_valid; 

  logic ser_data_o; 
  logic ser_data_val_o; 
  logic busy_ota_o; 

  logic how_many_data;

  int timeout_counter;

  mailbox mbx           = new(1);

  serializer ser_obj(
      .clk_i(clk),
      .srst_i(reset),

      .data_i(data_i),
      .data_mod_i(data_mod_i),
      .data_val_i(data_valid),

      .ser_data_o(ser_data_o),
      .ser_data_val_o(ser_data_val_o),
      .busy_o(busy_ota_o)
   );

  task cooldown_wait();
    begin
      timeout_counter <= 0;
      while( busy_ota_o && timeout_counter < MAX_COOLDOWN_TIMEOUT)
        begin
          @(posedge clk)
          timeout_counter <= timeout_counter + 1;
        end
      if(timeout_counter == MAX_COOLDOWN_TIMEOUT)
        begin
         $error("too much busy");  
        end    
    end
  endtask 

  task insert_data(
  input reset_t,
  input         [15:0] data_i_t,
  input         [3:0]  data_mod_i_t,
  input                data_val_i_t);
    begin
      reset           <= reset_t;
      data_i          <= data_i_t;
      data_mod_i      <= data_mod_i_t;
      data_valid      <= data_val_i_t;
      how_many_data   <= (data_mod_i_t == 0) ? 4'd16 : data_mod_i_t;
      timeout_counter <= 0;
    end
  endtask

   
  task correct_data_check(
  input reset_t,
  input         [15:0] data_i_t,
  input         [3:0]  data_mod_i_t,
  input                data_val_i_t,

  output  logic        res_flag_t);
    begin
      res_flag_t    <= 1'b0;
      while( !ser_data_val_o && timeout_counter < MAX_WORK_TIMEOUT )
        begin
         @(posedge clk)
         timeout_counter <= timeout_counter + 1;
        end

      for(int i = 0;i < how_many_data;i = i + 1)
        begin
          @(posedge clk)
          if(ser_data_o != data_i[15-i])
            begin
              $error("error, wrong data out on first cycle in %d el, need = %b, get = %b", i, data_i[15-i], ser_data_val_o);
              res_flag_t <= 1'b1;
            end

          if(busy_ota_o != 1)
            begin
              $error("error, must be busy on first cycle in %d el", i);
              res_flag_t <= 1'b1;
            end

          if(ser_data_val_o != 1)
            begin
              $error("error, must be correct data_flag on first cycle in %d el", i);
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
      res_flag_t    <= 1'b0;

      while( !busy_ota_o && timeout_counter < MAX_WORK_TIMEOUT )
        begin
          @(posedge clk)
          timeout_counter <= timeout_counter + 1;
        end

      if(busy_ota_o == 1)
        begin
          $error("error, mustn't be busy ");
          res_flag_t <= 1'b1;
        end

      data_valid <= 1'b0;
    end
  endtask


  task reset_check_task(
  input reset_t,
  input         [15:0] data_i_t,
  input         [3:0]  data_mod_i_t,
  input                data_val_i_t,

  output  logic        res_flag_t
  );
    begin    
      res_flag_t    <= 1'b0;

      while( !busy_ota_o && timeout_counter < MAX_WORK_TIMEOUT )
        begin
          @(posedge clk)
          timeout_counter <= timeout_counter + 1;
        end
      data_valid <= 1'b0; 
      if(busy_ota_o == 1)
        begin
          reset_t <= 1;
          timeout_counter <= 0;
        end

      while( busy_ota_o && timeout_counter < MAX_WORK_TIMEOUT )
        begin
          @(posedge clk)
          timeout_counter <= timeout_counter + 1;
        end

      if(timeout_counter == MAX_WORK_TIMEOUT)
        res_flag_t <= 1'b1;  
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
     fork
        begin
          int first_thread_param = 0;
          $display("first data test start");
          insert_data(1'b0, 16'b1011000000000000, 4'd6, 1'b1);
          mbx.put(1);
          while(first_thread_param != -1)
          begin
            @(posedge clk);
            mbx.try_peek(first_thread_param);
          end
          mbx.get(first_thread_param);

          cooldown_wait();
          $display("second data test start");
          insert_data(1'b0, 16'b1011000000000101, 4'd0, 1'b1);
          mbx.put(2);
          while(first_thread_param != -2)
          begin
            @(posedge clk);
            mbx.try_peek(first_thread_param);
          end
          mbx.get(first_thread_param);

          cooldown_wait();
          $display("first wrong input test start");
          insert_data(1'b0, 16'b1011000000000101, 4'd1, 1'b1);
          mbx.put(3);
          while(first_thread_param != -3)
          begin
            @(posedge clk);
            mbx.try_peek(first_thread_param);
          end
          mbx.get(first_thread_param);

          cooldown_wait();
          $display("second wrong input test start");
          insert_data(1'b0, 16'b1011000000000101, 4'd2, 1'b1);
          mbx.put(4);
          while(first_thread_param != -4)
          begin
            @(posedge clk);
            mbx.try_peek(first_thread_param);
          end
          mbx.get(first_thread_param);

          cooldown_wait();
          $display("reset test start");
          insert_data(1'b0, 16'b1011000000000101, 4'd2, 1'b1);
          mbx.put(5);
          while(first_thread_param != -5)
          begin
            @(posedge clk);
            mbx.try_peek(first_thread_param);
          end
          mbx.get(first_thread_param);
        end

        begin
          int second_thread_param = 0;
          logic task_res_flag;
          //d1
          while(second_thread_param != 1)
            begin
              @(posedge clk);
              mbx.try_peek(second_thread_param);
            end
          mbx.get(second_thread_param);
          correct_data_check(1'b0, 16'b1011000000000000, 4'd6, 1'b1, task_res_flag);
          if( task_res_flag )
            $error("first data test wrong");
          else
            $display("first data test ok");
          mbx.put(-1);

          //d2
          while(second_thread_param != 2)
            begin
              @(posedge clk);
              mbx.try_peek(second_thread_param);
            end
          mbx.get(second_thread_param);
          correct_data_check(1'b0, 16'b1011000000000101, 4'd0, 1'b1, task_res_flag);
          if( task_res_flag )
            $error("second data test wrong");
          else
            $display("second data test ok"); 
          mbx.put(-2);

          //w1
          while(second_thread_param != 3)
            begin
              @(posedge clk);
              mbx.try_peek(second_thread_param);
            end
          mbx.get(second_thread_param);
          wrong_data_check_task(1'b0, 16'b1011000000000101, 4'd1, 1'b1, task_res_flag);
          if( task_res_flag )
            $error("first wrong input test wrong");
          else
            $display("first wrong input test ok");
          mbx.put(-3);

          //w2
          while(second_thread_param != 4)
            begin
              @(posedge clk);
              mbx.try_peek(second_thread_param);
            end
          mbx.get(second_thread_param);
          wrong_data_check_task(1'b0, 16'b1011000000000101, 4'd1, 1'b1, task_res_flag);
          if( task_res_flag )
            $error("second wrong input test wrong");
          else
            $display("second wrong input test ok");
          mbx.put(-4);

          //r1
          while(second_thread_param != 5)
            begin
              @(posedge clk);
              mbx.try_peek(second_thread_param);
            end
          mbx.get(second_thread_param);
          reset_check_task(1'b0, 16'b1011000000000101, 4'd2, 1'b1, task_res_flag);
          if( task_res_flag )
            $error("reset test wrong");
          else
            $display("reset test ok");
          mbx.put(-5);

        end
      join

    end
  
endmodule
