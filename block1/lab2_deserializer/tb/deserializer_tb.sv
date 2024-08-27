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

  task generate_value();
    logic [15:0] local_val;
    cnt = 0;
    local_val = $urandom();
    while(cnt != 16)
      begin
        data_val <= 0;
        if(!($urandom() % 6 == 0)) // +- every 6 posedge clk we don't give value
          begin
            data <= local_val[15-cnt];
            data_val <= 1;
            cnt <= cnt + 1;
          end
        ##1;
      end
    cnt = 0;
    //$display("i put %b", local_val);
    data_val <= 0;
    mbx.put(local_val);
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

    repeat ( 600 ) generate_value();

    ##40;
    $display("all is ok");
    $stop();
  end
endmodule
