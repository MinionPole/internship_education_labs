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
  ) traffic_lights_obj (
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
  localparam int GREEN_BLINK_TIME_MS = BLINK_HALF_PERIOD_MS * (2 * BLINK_GREEN_TIME_TICK + 1);

  longint red_time_ms = 100, yellow_time_ms = 30, green_time_ms = 50;
  longint prev_time;

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

  task change_params(longint new_red_time_ms, longint new_yellow_time_ms, longint new_green_time_ms);
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
      cmd_data_i  <= (new_green_time_ms);
      ##1;
      cmd_type_i  <= 3'b100;
      cmd_valid_i <= 1;
      cmd_data_i  <= (new_red_time_ms);
      ##1;
      cmd_type_i  <= 3'b101;
      cmd_valid_i <= 1;
      cmd_data_i  <= (new_yellow_time_ms);
      ##1;
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

  task make_srst();
    ##1;
    srst <= 1'b1;
    ##1;
    srst <= 1'b0;
  endtask

  initial
    begin

      make_srst();
      check_value();

      $display("success test");
      $stop();
    end

endmodule