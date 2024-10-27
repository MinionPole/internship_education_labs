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

  enum logic [3:0] { OFF_S,
                     RED_S,
                     RED_YELLOW_S,
                     GREEN_S,
                     GREEN_BLINK_S,
                     YELLOW_S,
                     YELLOW_BLINK_S } prev_state = OFF_S, now_state;

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
  localparam longint CLK_FREQ_HZ         = 2000;
  localparam longint CLK_TIME            = (1000000) * 1.0 / (2.0 * CLK_FREQ_HZ);
  localparam longint GREEN_BLINK_TIME_US = BLINK_HALF_PERIOD_MS * 1000 * (2 * BLINK_GREEN_TIME_TICK + 1);

  longint red_time_us = 100000, yellow_time_us = 30000, green_time_us = 50000;
  longint prev_time;

  initial
    begin
      clk = 0;
      forever #CLK_TIME clk = !clk;
    end

  task change_params(longint new_red_time_us, longint new_yellow_time_us, longint new_green_time_us);
    begin
      red_time_us    = new_red_time_us;
      yellow_time_us = new_yellow_time_us;
      green_time_us  = new_green_time_us;
      ##1;
      cmd_type_i  <= 3'b010;
      cmd_valid_i <= 1;
      mbx.put(1);
      ##1;
      cmd_type_i  <= 3'b011;
      cmd_valid_i <= 1;
      cmd_data_i  <= (new_green_time_us / 1000);
      ##1;
      cmd_type_i  <= 3'b100;
      cmd_valid_i <= 1;
      cmd_data_i  <= (new_red_time_us / 1000);
      ##1;
      cmd_type_i  <= 3'b101;
      cmd_valid_i <= 1;
      cmd_data_i  <= (new_yellow_time_us / 1000);
      ##1;
      cmd_type_i  <= 3'b000;
      cmd_valid_i <= 1;
      ##1;
      cmd_valid_i <= 0;
    end
  endtask

  task check_value();
  
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

      ##1;
      cmd_type_i = 0;
      cmd_valid_i = 1;
      ##1;
      cmd_type_i = 0;
      cmd_valid_i = 0;
      
      ##1000;
      change_params(50000, 100000, 30000);
      ##1000;
      for(int i = 0;i < 10;i++)
        begin
          longint temp1, temp2, temp3, all_time;
          temp1 = ($urandom() % 2000000)+10000;
          temp2 = ($urandom() % 2000000)+10000;
          temp3 = ($urandom() % 2000000)+10000;
          all_time = temp1+temp2+temp3+GREEN_BLINK_TIME_US+RED_YELLOW_MS*1000;
          change_params(temp1, temp2, temp3);
          ##(all_time/CLK_TIME/2+50);
        end
      $display("success test");
      $stop();
    end

endmodule