module debouncer_tb #(
  parameter CLK_FREQ_MHZ = 150,
  parameter GLITCH_TIME_NS = 10
);

  localparam int LIMIT = (CLK_FREQ_MHZ * GLITCH_TIME_NS + 999) / 1000; 

  /*
  correct work - is
  1) in previous LIMIT+1 tacts button is pressed all except previous(because we has delay in one tact)
  2) we didn't get key_pressed_stb last (LIMIT - 1) tact
  */

  logic [LIMIT - 1: 0] key_mem;
  logic [LIMIT - 1: 0] pressed_out_mem;

  logic                       clk;
  logic                       key;

  logic                       key_pressed_stb;

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

  function logic check_pressed_mem();
    if(LIMIT == 1)
      return 1;
    return (pressed_out_mem[LIMIT - 2:0] == '0);
  endfunction

  task generate_value(
    logic             input_data,
    logic             rand_data_flag
  );
    if( rand_data_flag )
      input_data = $urandom();
    ##1;
    key <= input_data;
  endtask

  task check_pressed_value();
    forever
      begin
        if(key_pressed_stb)
          begin
            if(!key_mem && check_pressed_mem())
              $display("succed test");
            else
              begin
                if(key_mem)
                  $error("button was bounce %b\n", key_mem);
                if(!check_pressed_mem())
                  $error("you already signilized earlier");
                $stop();
              end
          end
        key_mem         <= {key_mem[LIMIT-2:0]        , key};
        pressed_out_mem <= {pressed_out_mem[LIMIT-2:0], key_pressed_stb};
        ##1;
      end
  endtask


  task check_unpressed_value();
    forever
      begin
        if(!key_pressed_stb)
          begin
            if(!key_mem && check_pressed_mem())
              begin
                $error("button should be pressed");
                $stop();
              end
          end
        ##1;
      end
  endtask

  initial
    begin

      //$display("limit is %d", LIMIT);

      $display("start tb with CLK_FREQ_MHZ = %d, GLITCH_TIME_NS = %d", CLK_FREQ_MHZ, GLITCH_TIME_NS);
      fork
        check_pressed_value();
        check_unpressed_value();
      join_none

      repeat(100)  generate_value('0, 0);
      repeat(100)  generate_value('1, 0);
      repeat(LIMIT * 1000) generate_value('0, 1);
      ##1;
      $display("success tb with CLK_FREQ_MHZ = %d, GLITCH_TIME_NS = %d", CLK_FREQ_MHZ, GLITCH_TIME_NS);
      $stop();
    end

endmodule