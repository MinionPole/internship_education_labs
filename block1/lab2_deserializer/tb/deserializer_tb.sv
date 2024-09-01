`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.08.2024 22:14:01
// Design Name: 
// Module Name: deserializer_tb
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


module deserializer_tb;
  logic          clk;
  logic          srst;
  logic          data;
  logic          data_val;

  logic [15:0]  deser_data;
  logic         deser_data_val;

  deserializer deserializer_obj(
    .clk_i(clk),
    .srst_i(srst),
    .data_i(data),
    .data_val_i(data_val),

    .deser_data_o(deser_data),
    .deser_data_val_o(deser_data_val)
  );

  mailbox mbx;
  int cnt = 0;
  default clocking cb @( posedge clk );
  endclocking

  initial
    begin
      clk = 0;
      forever #5 clk = !clk;
    end

  task generate_test_with_delay(
    logic [15:0] input_data,
    int delta,
    logic rand_data_flag,
    logic rand_delta_flag
  );
    if(rand_data_flag)
      input_data = $urandom();

    for(int i = 0; i < 16; i++)
      begin
        if(rand_delta_flag)
          delta = ($urandom() % 50) + 2;
        for(int j = 1; j < delta; j++)
          begin
            if(j == 1)
              begin
                data     <= input_data[15-i];
                data_val <= 1;
              end
            else
              begin
                data_val <= 0;
              end
            ##1;
          end
      end
    //$display("i put %b", input_data);
    data_val <= 0;
    mbx.put(input_data);
  endtask
  
  task check_value();
    logic [15:0] local_val;
    forever
      begin
        if(deser_data_val)
          begin
            mbx.get(local_val);
            if(!(local_val === deser_data))
              begin
                $error("dismatch values get %b, requires %b", deser_data, local_val);
                $stop;
              end
            else
              $display("successful test value is %b", local_val);  
          end
        ##1;
      end
  endtask

  task make_srst();
    ##1;
    srst <= 1'b1;
    ##1;
    srst <= 1'b0;
  endtask

  initial
  begin
    mbx = new();
    make_srst();

    fork
      check_value();
    join_none

    generate_test_with_delay('0, 2, 0, 0);
    generate_test_with_delay('1, 2, 0, 0);
    for(int i = 2; i < 20;i++)
      begin
        generate_test_with_delay('0, i, 1, 0);
      end

    repeat ( 1000 ) generate_test_with_delay('0, 2, 1, 1);

    ##40;
    $display("all is ok");
    $stop();
  end

endmodule
