`timescale 1us/1us
module traffic_lighs_tb #(
  parameter BLINK_HALF_PERIOD_MS  = 4,
  parameter BLINK_GREEN_TIME_TICK = 0,
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

  mailbox mbx;
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

  task get_current_out();
    begin
      if(!red_o && !yellow_o && !green_o)
        now_state = OFF_S;

      if(red_o && !yellow_o && !green_o)
        now_state = RED_S;

      if(red_o && yellow_o && !green_o)
        now_state = RED_YELLOW_S;

      if(!red_o && yellow_o && !green_o)
        if(prev_state == OFF_S)
          begin
            now_state = YELLOW_BLINK_S;
          end
        else
          now_state   = YELLOW_S;

      if(!red_o && !yellow_o && green_o)
        if(prev_state == OFF_S)
          begin
            now_state = GREEN_BLINK_S;
          end
        else
          now_state   = GREEN_S;
    end
  endtask

  function longint get_time();
    return $time() - prev_time;
  endfunction

  task check_value();
    int delta;
    int input_data;
    forever
      begin
        get_current_out();

        if(mbx.try_get(input_data))
          prev_state = OFF_S;

        if(now_state == prev_state)
          begin
            //$display("the same signal %s, %s", now_state, prev_state);
          end
        else
          begin
            case(prev_state)
              OFF_S:
                begin
                  if(now_state == YELLOW_BLINK_S)
                    begin
                      prev_state = now_state;
                    end
                
                  if(now_state == GREEN_BLINK_S)
                    begin
                      $display("prev time is are %d, nowtime is %d", prev_time, ($time() - BLINK_HALF_PERIOD_MS * 1000));
                      prev_state = GREEN_BLINK_S;
                      delta = get_time() - green_time_us - 1000 * BLINK_HALF_PERIOD_MS;
                      prev_time = $time() - 1000 * BLINK_HALF_PERIOD_MS;
                      if((delta) * 1.0 / green_time_us > 0.05 || (delta) * 1.0 / green_time_us < -0.05)
                        begin
                          $error("not correct time to green light");
                          $stop();
                        end
                    end

                  if(now_state == RED_S)
                    begin
                      prev_state  = now_state;
                      prev_time = $time();
                    end
                end

              YELLOW_BLINK_S:
                begin
                  if(now_state == RED_S)
                    begin
                      prev_state  = now_state;
                      prev_time = $time();
                    end
                  else
                    if(now_state != OFF_S)
                      begin
                        $error("wrong order from yellow_blink_s");
                        $stop();
                      end
                    
                end

              RED_S:
                begin
                  if(now_state == RED_YELLOW_S)
                    begin
                      prev_state = now_state;
                      delta = get_time() - red_time_us;
                      prev_time = $time();
                      if((delta) * 1.0 / (red_time_us) > 0.05 || (delta) * 1.0 / (red_time_us) < -0.05)
                        begin
                          $error("not correct time to red light");
                          $stop();
                        end
                    end
                  else
                    if(now_state != OFF_S)
                      begin
                        $error("wrong order from red light");
                        $stop();
                      end
                end

              RED_YELLOW_S:
                begin
                  if(now_state == GREEN_S)
                    begin
                      prev_state = now_state;
                      delta = get_time() - RED_YELLOW_MS * 1000;
                      prev_time = $time();
                      if((delta) * 1.0 / (RED_YELLOW_MS * 1000) > 0.05 || (delta) * 1.0 / (RED_YELLOW_MS * 1000) < -0.05)
                        begin
                          $error("not correct time to red+yellow light");
                          $stop();
                        end
                    end
                  else
                    if(now_state != OFF_S)
                      begin
                        $error("wrong order from red+yellow light");
                        $stop();
                      end
                end

              GREEN_S:
                begin
                  if(now_state != OFF_S)
                    begin
                      if(now_state == YELLOW_S && BLINK_GREEN_TIME_TICK == 0)
                        begin
                          $display("prev time is are %d, nowtime is %d", prev_time, ($time()));
                          prev_state = now_state;
                          delta = get_time() - green_time_us;
                          prev_time = $time();
                          if((delta) * 1.0 / green_time_us > 0.05 || (delta) * 1.0 / green_time_us < -0.05)
                            begin
                              $error("not correct time to green light");
                              $stop();
                            end
                        end
                      else
                        begin
                          $error("wrong order from green_lights");
                          $stop();
                        end
                    end
                  else
                      prev_state = now_state;
                end

              GREEN_BLINK_S:
                begin
                  if(now_state == YELLOW_S)
                    begin
                      prev_state = now_state;
                      delta = get_time() - (GREEN_BLINK_TIME_US);
                      prev_time = $time();
                      if((delta) * 1.0 / (GREEN_BLINK_TIME_US) > 0.05 || (delta) * 1.0 / (GREEN_BLINK_TIME_US) < -0.05)
                        begin
                          $error("not correct time to green_blink light");
                          $stop();
                        end
                    end
                  else
                    if(now_state != OFF_S && now_state != GREEN_S)
                      begin
                        $error("wrong order from green_blink light");
                        $stop();
                      end
                end

              YELLOW_S:
                begin
                  if(now_state == RED_S)
                    begin
                      prev_state = now_state;
                      delta = get_time() - (yellow_time_us);
                      prev_time = $time();
                      if((delta) * 1.0 / (yellow_time_us) > 0.05 || (delta) * 1.0 / (yellow_time_us) < -0.05)
                        begin
                          $error("not correct time to yellow light");
                          $stop();
                        end
                    end
                  else
                    if(now_state != OFF_S)
                      begin
                        $error("wrong order from yellow light");
                        $stop();
                      end
                end

            endcase

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