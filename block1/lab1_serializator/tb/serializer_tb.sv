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

  logic[3:0] how_many_data;

  int timeout_counter;

  mailbox mbx1 = new(1);
  mailbox mbx2 = new(1);

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
      data_valid <= 1'b0;
      for(int i = 0;i < how_many_data;i = i + 1)
        begin

          if(! ( ser_data_o === data_i[15-i] ) )
            begin
              $error("error, wrong data out on first cycle in %d el, need = %b, get = %b", i, data_i[15-i], ser_data_o);
              res_flag_t <= 1'b1;
            end

          if( !( busy_ota_o === 1 ) )
            begin
              $error("error, must be busy on first cycle in %d el", i);
              res_flag_t <= 1'b1;
            end

          if( !(ser_data_val_o === 1) )
            begin
              $error("error, must be correct data_flag on first cycle in %d el", i);
              res_flag_t <= 1'b1;
            end
          @(posedge clk);
        end
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

      if(busy_ota_o === 1)
        begin
          $error("error, mustn't be busy ");
          res_flag_t <= 1'b1;
        end

      data_valid <= 1'b0;
    end
  endtask

  task data_wait_first_thread(
  input int wait_num,
  input mailbox mbx
  );
    begin
      int local_value;
      local_value <= 0;
      while(local_value != wait_num)
        begin
          @(posedge clk);
          mbx.try_peek(local_value);
          //$display("wait %d, loc_val is %d", wait_num, local_value);
        end
      mbx.get(local_value);
    end
  endtask

  task data_wait_second_thread(
  input int wait_num,
  input mailbox mbx
  );
    begin
      int local_value;
      local_value <= 0;
      while(local_value != wait_num)
        begin
          @(posedge clk);
          mbx.try_peek(local_value);
          //$display("wait %d, loc_val is %d", wait_num, local_value);
        end
      mbx.get(local_value);
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
      if(busy_ota_o === 1)
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
          $display("first data test start");
          insert_data(1'b0, 16'b1011000000000000, 4'd6, 1'b1);
          mbx1.put(1);
          data_wait_first_thread(-1, mbx2);

          cooldown_wait();
          $display("second data test start");
          insert_data(1'b0, 16'b1011000000000101, 4'd0, 1'b1);
          mbx1.put(1);
          data_wait_first_thread(-1, mbx2);

          cooldown_wait();
          $display("third data test start");
          insert_data(1'b0, 16'b0000000001100101, 4'd15, 1'b1);
          mbx1.put(1);
          data_wait_first_thread(-1, mbx2);

          cooldown_wait();
          $display("forth data test start");
          insert_data(1'b0, 16'b0000000000000000, 4'd8, 1'b1);
          mbx1.put(1);
          data_wait_first_thread(-1, mbx2);

          cooldown_wait();
          $display("fifth data test start");
          insert_data(1'b0, 16'b1111111111111111, 4'd3, 1'b1);
          mbx1.put(1);
          data_wait_first_thread(-1, mbx2);

          cooldown_wait();
          $display("sixth data test start");
          insert_data(1'b0, 16'b0101100000110000, 4'd13, 1'b1);
          mbx1.put(1);
          data_wait_first_thread(-1, mbx2);

          cooldown_wait();
          $display("first wrong input test start");
          insert_data(1'b0, 16'b1011000000000101, 4'd1, 1'b1);
          mbx1.put(1);
          data_wait_first_thread(-1, mbx2);

          cooldown_wait();
          $display("second wrong input test start");
          insert_data(1'b0, 16'b1011000000000101, 4'd2, 1'b1);
          mbx1.put(1);
          data_wait_first_thread(-1, mbx2);

          cooldown_wait();
          $display("reset test start");
          insert_data(1'b0, 16'b1011000000000101, 4'd2, 1'b1);
          mbx1.put(1);
          data_wait_first_thread(-1, mbx2);
        end

        begin
          logic task_res_flag;
          //d1
          data_wait_second_thread(1, mbx1);
          correct_data_check(1'b0, 16'b1011000000000000, 4'd6, 1'b1, task_res_flag);
          if( task_res_flag )
            begin
              $error("first data test wrong");
              $stop;
            end
          else
            $display("first data test ok");
          mbx2.put(-1);

          //d2
          data_wait_second_thread(1, mbx1);
          correct_data_check(1'b0, 16'b1011000000000101, 4'd0, 1'b1, task_res_flag);
          if( task_res_flag )
            begin
              $error("second data test wrong");
              $stop;
            end
          else
            $display("second data test ok");
          mbx2.put(-1);

          //d3
          data_wait_second_thread(1, mbx1);
          correct_data_check(1'b0, 16'b0000000001100101, 4'd15, 1'b1, task_res_flag);
          if( task_res_flag )
            begin
              $error("third data test wrong");
              $stop;
            end
          else
            $display("third data test ok");
          mbx2.put(-1);

          //d4
          data_wait_second_thread(1, mbx1);
          correct_data_check(1'b0, 16'b0000000000000000, 4'd8, 1'b1, task_res_flag);
          if( task_res_flag )
            begin
              $error("forth data test wrong");
              $stop;
            end
          else
            $display("forth data test ok");
          mbx2.put(-1);

          //d5
          data_wait_second_thread(1, mbx1);
          correct_data_check(1'b0, 16'b1111111111111111, 4'd3, 1'b1, task_res_flag);
          if( task_res_flag )
            begin
              $error("fifth data test wrong");
              $stop;
            end
          else
            $display("fifth data test ok");
          mbx2.put(-1);

          //d6
          data_wait_second_thread(1, mbx1);
          correct_data_check(1'b0, 16'b0101100000110000, 4'd13, 1'b1, task_res_flag);
          if( task_res_flag )
            begin
              $error("sixth data test wrong");
              $stop;
            end
          else
            $display("sixth data test ok");
          mbx2.put(-1);

          //w1
          data_wait_second_thread(1, mbx1);
          wrong_data_check_task(1'b0, 16'b1011000000000101, 4'd1, 1'b1, task_res_flag);
          if( task_res_flag )
            begin
              $error("first wrong input test wrong");
              $stop;
            end
          else
            $display("first wrong input test ok");
          mbx2.put(-1);

          //w2
          data_wait_second_thread(1, mbx1);
          wrong_data_check_task(1'b0, 16'b1011000000000101, 4'd1, 1'b1, task_res_flag);
          if( task_res_flag )
            begin
              $error("second wrong input test wrong");
              $stop;
            end
          else
            $display("second wrong input test ok");
          mbx2.put(-1);

          //r1
          data_wait_second_thread(1, mbx1);
          reset_check_task(1'b0, 16'b1011000000000101, 4'd2, 1'b1, task_res_flag);
          if( task_res_flag )
            begin
              $error("reset test wrong");
              $stop;
            end
          else
            $display("reset test ok");
          mbx2.put(-1);

        end
      join

    end
  
endmodule
