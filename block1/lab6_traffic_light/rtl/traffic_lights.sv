module traffic_lights #(
  parameter BLINK_HALF_PERIOD_MS  = 4,
  parameter BLINK_GREEN_TIME_TICK = 8,
  parameter RED_YELLOW_MS         = 10
)(
  input                       clk_i,

  input                       srst_i,
  input [2:0]                 cmd_type_i,
  input                       cmd_valid_i,
  input [15:0]                cmd_data_i,

  output logic                red_o,
  output logic                yellow_o,
  output logic                green_o

);

  enum logic [2:0] { OFF_S,
                     RED_S,
                     RED_YELLOW_S,
                     GREEN_S,
                     GREEN_BLINK_S,
                     YELLOW_S,
                     YELLOW_BLINK_S } state, next_state;

  localparam int CLK_HZ = 2000;
  localparam int GREEN_BLINK_TIME_MS = BLINK_HALF_PERIOD_MS * (2 * BLINK_GREEN_TIME_TICK + 1);
  int red_time_ms, yellow_time_ms, green_time_ms;
  int red_time_clk, yellow_time_clk, green_time_clk, red_yellow_time_clk, blink_state_clk, green_blink_time_clk;
  int state_cnt, blink_state_cnt;

  always_comb
    begin
      red_time_clk         = CLK_HZ * red_time_ms / 1000;
    end
  
  always_comb
    begin
      yellow_time_clk      = CLK_HZ * yellow_time_ms / 1000;
    end  
  
  always_comb
    begin
      green_time_clk       = CLK_HZ * green_time_ms / 1000;
    end

  always_comb
    begin
      red_yellow_time_clk  = CLK_HZ * RED_YELLOW_MS / 1000;
    end

  always_comb
    begin
      blink_state_clk      = CLK_HZ * BLINK_HALF_PERIOD_MS / 1000 * 2;
    end  

  always_comb
    begin
      green_blink_time_clk <= CLK_HZ * GREEN_BLINK_TIME_MS / 1000;
    end    

  always_ff @( posedge clk_i )
    begin
      if(srst_i)
        red_time_ms <= 100;
      else
        if(state == YELLOW_BLINK_S && cmd_valid_i && cmd_type_i == 3'b100)
          red_time_ms <= cmd_data_i;
    end

  always_ff @( posedge clk_i )
    begin
      if(srst_i)
        yellow_time_ms <= 30;
      else
        if(state == YELLOW_BLINK_S && cmd_valid_i && cmd_type_i == 3'b101)
          yellow_time_ms <= cmd_data_i;
    end
  
  always_ff @( posedge clk_i )
    begin
      if(srst_i)
        green_time_ms <= 50;
      else
        if(state == YELLOW_BLINK_S && cmd_valid_i && cmd_type_i == 3'b011)
          green_time_ms <= cmd_data_i;
    end

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        state_cnt <= 0;
      else
        if(state != next_state)
          state_cnt <= 1;
        else
          state_cnt <= state_cnt + 1;
    end
  
  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        blink_state_cnt <= 0;
      else
        if(state != next_state)
          blink_state_cnt <= 0;
        else
          if(blink_state_cnt == blink_state_clk)
            blink_state_cnt <= 0;
          else
            blink_state_cnt <= blink_state_cnt + 1;
    end


  always_ff @( posedge clk_i )
    if( srst_i )
      state <= RED_S;
    else
      state <= next_state;

  always_comb
    begin
      next_state = state;

      case( state )
        OFF_S:
          begin
            if(cmd_valid_i && cmd_type_i == 3'b000)
              next_state = RED_S;
          end

        RED_S:
          begin
            if(state_cnt == red_time_clk)
              next_state = RED_YELLOW_S;
            if(cmd_valid_i && cmd_type_i == 3'b001)
              next_state = OFF_S;
            if(cmd_valid_i && cmd_type_i == 3'b010)
              next_state = YELLOW_BLINK_S;
          end

        RED_YELLOW_S:
          begin
            if(state_cnt == red_yellow_time_clk)
              next_state = GREEN_S;
            if(cmd_valid_i && cmd_type_i == 3'b001)
              next_state = OFF_S;
            if(cmd_valid_i && cmd_type_i == 3'b010)
              next_state = YELLOW_BLINK_S;
          end

        GREEN_S:
          begin
            if(state_cnt == green_time_clk)
              if(BLINK_GREEN_TIME_TICK != 0)
                next_state = GREEN_BLINK_S;
              else
                next_state = YELLOW_S;
            if(cmd_valid_i && cmd_type_i == 3'b001)
              next_state = OFF_S;
            if(cmd_valid_i && cmd_type_i == 3'b010)
              next_state = YELLOW_BLINK_S;
          end

        GREEN_BLINK_S:
          begin
            if(state_cnt == green_blink_time_clk)
              next_state = YELLOW_S;
            if(cmd_valid_i && cmd_type_i == 3'b001)
              next_state = OFF_S;
            if(cmd_valid_i && cmd_type_i == 3'b010)
              next_state = YELLOW_BLINK_S;
          end

        YELLOW_S:
          begin
            if(state_cnt == yellow_time_clk)
              next_state = RED_S;
            if(cmd_valid_i && cmd_type_i == 3'b001)
              next_state = OFF_S;
            if(cmd_valid_i && cmd_type_i == 3'b010)
              next_state = YELLOW_BLINK_S;
          end

        YELLOW_BLINK_S:
          begin
            if(cmd_valid_i && cmd_type_i == 3'b000)
              next_state = RED_S;
            if(cmd_valid_i && cmd_type_i == 3'b001)
              next_state = OFF_S;
          end

        default:
          begin
            next_state = OFF_S;
          end

      endcase
    end

  always_comb
    begin
      green_o  = 0;
      case( state )
        GREEN_S:
          begin
            green_o  = 1;
          end

        GREEN_BLINK_S:
          begin
            if(2 * blink_state_cnt > blink_state_clk)
              green_o  = 1;
          end
      endcase
    end
  
  always_comb
    begin
      yellow_o = 0;
      case( state )

        RED_YELLOW_S:
          yellow_o = 1;

        YELLOW_S:
          yellow_o = 1;

        YELLOW_BLINK_S:
          if(2 * blink_state_cnt > blink_state_clk)
            yellow_o = 1;

      endcase
    end

  always_comb
    begin
      red_o  = 0;
      case( state )

        RED_S:
          red_o  = 1;

        RED_YELLOW_S:
          red_o  = 1;

      endcase
    end

endmodule