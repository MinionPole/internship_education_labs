`timescale 1us/1us
module traffic_lighs_tb #(
  parameter BLINK_HALF_PERIOD_MS  = 4,
  parameter BLINK_GREEN_TIME_TICK = 8,
  parameter RED_YELLOW_MS         = 10
);

  logic                       clk;

  logic                       srst;
  logic [2:0]                 cmd_type_i;
  logic                       cmd_valid_i;
  logic [15:0]                cmd_data_i;

  logic                 red_o;
  logic                 yellow_o;
  logic                 green_o;

  traffic_lights#(
    .BLINK_HALF_PERIOD_MS      ( BLINK_HALF_PERIOD_MS ),
    .BLINK_GREEN_TIME_TICK     ( BLINK_GREEN_TIME_TICK),
    .RED_YELLOW_MS             ( RED_YELLOW_MS        )
  ) traffic_lights_dut (
    .clk_i                     (clk                   ),
    .srst_i                    (srst                  ),
    .cmd_type_i                (cmd_type_i            ),
    .cmd_valid_i               (cmd_valid_i           ),
    .cmd_data_i                (cmd_data_i            ),

    .red_o                     (red_o                 ),
    .yellow_o                  (yellow_o              ),
    .green_o                   (green_o               )
  );

  default clocking cb @( posedge clk );
  endclocking
  localparam CLK_FREQ_KHZ            = 2;
  localparam CLK_TIME                = (1000) * 1.0 / (2.0 * CLK_FREQ_KHZ);
  localparam int GREEN_BLINK_TIME_MS = BLINK_HALF_PERIOD_MS * (2 * BLINK_GREEN_TIME_TICK);

  int red_time_ms = 100, yellow_time_ms = 30, green_time_ms = 50;
  int prev_time;
  mailbox mbx;
  

  int red_time_clk, yellow_time_clk, green_time_clk, red_yellow_time_clk, blink_state_clk, green_blink_time_clk;
  assign red_time_clk         = CLK_FREQ_KHZ * red_time_ms;
  assign yellow_time_clk      = CLK_FREQ_KHZ * yellow_time_ms;
  assign green_time_clk       = CLK_FREQ_KHZ * green_time_ms;
  assign red_yellow_time_clk  = CLK_FREQ_KHZ * RED_YELLOW_MS;
  assign blink_state_clk      = CLK_FREQ_KHZ * BLINK_HALF_PERIOD_MS * 2; 
  assign green_blink_time_clk = CLK_FREQ_KHZ * GREEN_BLINK_TIME_MS; 

  initial
    begin
      clk = 0;
      forever #CLK_TIME clk = !clk;
    end

  task change_params(int new_red_time_ms, int new_yellow_time_ms, int new_green_time_ms);
    begin
      red_time_ms    = new_red_time_ms;
      yellow_time_ms = new_yellow_time_ms;
      green_time_ms  = new_green_time_ms;
      ##1;
      cmd_type_i  <= 3'b010;
      cmd_valid_i <= 1;
      ##1;
      cmd_type_i  <= 3'b011;
      cmd_valid_i <= 1;
      cmd_data_i  <= new_green_time_ms;
      ##1;
      cmd_type_i  <= 3'b100;
      cmd_valid_i <= 1;
      cmd_data_i  <= new_red_time_ms;
      ##1;
      cmd_type_i  <= 3'b101;
      cmd_valid_i <= 1;
      cmd_data_i  <= new_yellow_time_ms;
      ##1;
      cmd_type_i  <= 3'b000;
      cmd_valid_i <= 1;
      ##1;
      cmd_valid_i <= 0;
    end
  endtask

  task wait_in_yellow();
    int wait_time;
    begin
      wait_time = $urandom() % 200 + 1;
      $display("time is wait_time");
      ##1;
      cmd_type_i  <= 3'b010;
      cmd_valid_i <= 1;
      mbx.put(wait_time);
      ##1;
      cmd_valid_i <= 0;
      ##(wait_time - 1);
      cmd_type_i  <= 3'b000;
      cmd_valid_i <= 1;
      ##1;
      cmd_valid_i <= 0;

    end
  endtask

  task check_value();
    repeat(red_time_clk)
      begin
        //
        if( !(red_o === 1 && yellow_o === 0 && green_o === 0))
          begin
            $display("%d %d %d", red_o, yellow_o, green_o);
            $error("!!!BAD STATE ON RED!!!");
            $stop();
          end
        ##1;
      end
    $display("success red");
    repeat(red_yellow_time_clk)
      begin
        if( !(red_o === 1 && yellow_o === 1 && green_o === 0))
          begin
            $display("%d %d %d", red_o, yellow_o, green_o);
            $error("!!!BAD STATE ON RED+YELLOW!!!");
            $stop();
          end
        ##1;
      end
    $display("success red+yellow");
    repeat(green_time_clk)
      begin
        if( !(red_o === 0 && yellow_o === 0 && green_o === 1))
          begin
            $display("%d %d %d", red_o, yellow_o, green_o);
            $error("!!!BAD STATE ON GREEN!!!");
            $stop();
          end
          
        ##1;
      end
    $display("success green");

    repeat(BLINK_GREEN_TIME_TICK)
      begin
        repeat(blink_state_clk / 2)
          begin
            if( !(red_o === 0 && yellow_o === 0 && green_o === 0))
              begin
                $display("%d %d %d", red_o, yellow_o, green_o);
                $error("!!!BAD STATE ON GREEN_BLINK_EMPTY!!!");
                $stop();
              end
            ##1;
          end
        repeat(blink_state_clk / 2)
          begin
            if( !(red_o === 0 && yellow_o === 0 && green_o === 1))
              begin
                $display("%d %d %d", red_o, yellow_o, green_o);
                $error("!!!BAD STATE ON GREEN_BLINK_LIGHT!!!");
                $stop();
              end
            ##1;
          end
      end
    $display("success greenblink");
    repeat(yellow_time_clk)
      begin
        if( !(red_o === 0 && yellow_o === 1 && green_o === 0))
          begin
            $display("%d %d %d", red_o, yellow_o, green_o);
            $error("!!!BAD STATE ON YELLOW!!!");
            $stop();
          end
        ##1;
      end
    $display("success yellow");

  endtask

  task check_yellow_state();
  int data_from_mbx;
  static int counter = 0;
    forever
      begin
        if(mbx.try_get(data_from_mbx))
          begin
            counter = 0;
            ##1;
            repeat(data_from_mbx)
              begin
                if(counter < (blink_state_clk / 2))
                  begin
                    if( !(red_o === 0 && yellow_o === 0 && green_o === 0))
                      begin
                        $display("%d %d %d", red_o, yellow_o, green_o);
                        $display("d - %d", data_from_mbx);
                        $display("c - %d", counter);
                        $display("bsc - %d", blink_state_clk);
                        $error("!!!BAD STATE ON YELLOW_BLINK_EMPTY!!!");
                        $stop();
                      end
                  end
                else
                  begin
                    if( !(red_o === 0 && yellow_o === 1 && green_o === 0))
                      begin
                        $display("%d %d %d", red_o, yellow_o, green_o);
                        $error("!!!BAD STATE ON YELLOW_BLINK_LIGHT!!!");
                        $stop();
                      end
                  end
                $display("time is %d, c - %d",$time(), counter);
                counter = (counter == blink_state_clk - 1) ? 0 : (counter + 1);
                ##1;
              end
          end
        else
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
      fork
        check_yellow_state();
      join_none
      make_srst();
      check_value();

      change_params(50, 100, 30);
      check_value();
      for(int i = 0;i < 40;i++)
        begin
          int gen_red_time_ms, gen_green_time_ms, gen_yellow_time_ms;
          gen_red_time_ms    = ($urandom() % 200) + 1;
          gen_green_time_ms  = ($urandom() % 200) + 1;
          gen_yellow_time_ms = ($urandom() % 200) + 1;
          change_params(gen_red_time_ms, gen_green_time_ms, gen_yellow_time_ms);
          check_value();
        end

      for(int i = 0;i < 40;i++)
        begin
          int gen_red_time_ms, gen_green_time_ms, gen_yellow_time_ms, all_time_in_clk, moment;
          gen_red_time_ms    = ($urandom() % 200) + 1;
          gen_green_time_ms  = ($urandom() % 200) + 1;
          gen_yellow_time_ms = ($urandom() % 200) + 1;
          all_time_in_clk    = (gen_red_time_ms+gen_green_time_ms+gen_yellow_time_ms+GREEN_BLINK_TIME_MS+RED_YELLOW_MS) * 1000 / CLK_TIME;
          change_params(gen_red_time_ms, gen_green_time_ms, gen_yellow_time_ms);
          moment             = ($urandom() % all_time_in_clk) + 1;
          ##(moment);
          wait_in_yellow();
          ##1;
        end
      $display("success tests");
      $stop();
    end

endmodule