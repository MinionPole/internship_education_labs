module debouncer_tb #(
  parameter CLK_FREQ_MHZ = 150,
  parameter GLITCH_TIME_NS = 10
);

  localparam int LIMIT = (CLK_FREQ_MHZ * GLITCH_TIME_NS + 999) / 1000; 

  logic                       clk;
  logic                       key;

  logic                       key_pressed_stb;

  mailbox mbx;
  int clk_counter = 0;

  debouncer#(
    .CLK_FREQ_MHZ       (CLK_FREQ_MHZ   ),
    .GLITCH_TIME_NS     (GLITCH_TIME_NS )
  ) debouncer_obj (
    .clk_i              (clk            ),
    .key_i              (key            ),

    .key_pressed_stb_o  (key_pressed_stb)
  );

  default clocking cb @( posedge clk );
  endclocking

  initial
    begin
      clk = 0;
      forever #5 clk = !clk;
    end

  initial
    begin
      clk_counter = 0;
      forever #10 clk_counter = clk_counter + 1;
    end

  task generate_value(
    logic [LIMIT - 1: 0]   input_data,
    logic                  rand_data_flag
  );
    if( rand_data_flag )
      begin
        input_data = $urandom();
        for( int i = 1; i < LIMIT / 32; i++ )
          begin
            input_data       = input_data << 32;
            input_data[31:0] = $urandom();
          end
        input_data[0]         = 1;
        input_data[LIMIT - 1] = 1;
        //$display("value is %b", input_data);
      end
    if(input_data == '0)
      mbx.put(clk_counter);
    for( int i = 0; i < LIMIT; i++ )
        begin
          ##1;
          key <= input_data[i];
        end
  endtask

  task check_value();
  int data_from_mbx;
    forever
      begin
        if(key_pressed_stb)
          begin
            //$display("%b and %b", key_mem, pressed_out_mem);
            if( !mbx.try_get(data_from_mbx) )
              begin
                $error("execute button without enough time");
                $stop();
              end
            $display((clk_counter - data_from_mbx) * 1000 * 1.0 / CLK_FREQ_MHZ);
            if( ((clk_counter - data_from_mbx) * 1000 * 1.0 / CLK_FREQ_MHZ - GLITCH_TIME_NS) * 1.0 / GLITCH_TIME_NS <= 0.02)
              $display("succed test");
            else
              $display("too much delay");
          end
        ##1;
      end
  endtask


  initial
    begin
      //$display("limit is %d", LIMIT);
      mbx = new();
      $display("start tb with CLK_FREQ_MHZ = %d, GLITCH_TIME_NS = %d", CLK_FREQ_MHZ, GLITCH_TIME_NS);
      fork
        check_value();
      join_none

      generate_value('0, 0);
      generate_value('1, 0);

      for(int i = 0; i < 20;i++)
        begin
          repeat(20)  generate_value('0, 1);
                      generate_value('0, 0);
          repeat(20)  generate_value('0, 1);
        end

      for(int i = 2; i < 10;i++)
        begin
          for(int j = 0; j < i;j++)
            begin
              generate_value('0, 0);
            end
        end

      for(int i = 0; i < 10;i++)
        begin
          repeat(20)  generate_value('0, 1);
          repeat(20)  generate_value('0, 1);
        end
      if(LIMIT != 1)
        begin
          mbx.put(clk_counter + 1); 
          generate_value('0 + 1'b1, 0);
          generate_value('0, 0);
          generate_value({1'b1, {LIMIT-1{1'b0}}}, 0);
        end

      ##1;
      key <= 1;
      ##40;
      if( mbx.num() != 0 )
        begin
          $error("Have bits in referance queues!");
          $stop();
        end

      $display("success tb with CLK_FREQ_MHZ = %d, GLITCH_TIME_NS = %d", CLK_FREQ_MHZ, GLITCH_TIME_NS);
      $stop();
    end

endmodule