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

  localparam logic[31:0] CLK_KHZ = 2;
  localparam logic[15:0] GREEN_BLINK_TIME_MS = BLINK_HALF_PERIOD_MS * (2 * BLINK_GREEN_TIME_TICK);
  localparam             BLINK_CNT_W = $clog2(CLK_KHZ * BLINK_HALF_PERIOD_MS * 2);
  localparam             CNT_W = $clog2(CLK_KHZ) + 16;
  logic[15:0]          red_time_ms, yellow_time_ms, green_time_ms;
  logic[47:0]          red_time_clk, yellow_time_clk, green_time_clk, red_yellow_time_clk, blink_state_clk, green_blink_time_clk;
  logic[CNT_W:0]       state_cnt;
  logic[BLINK_CNT_W:0] blink_state_cnt;

  assign red_time_clk         = CLK_KHZ * red_time_ms - 1;
  
  assign yellow_time_clk      = CLK_KHZ * yellow_time_ms - 1;
  
  assign green_time_clk       = CLK_KHZ * green_time_ms - 1;

  assign red_yellow_time_clk  = CLK_KHZ * RED_YELLOW_MS - 1;

  assign blink_state_clk      = CLK_KHZ * BLINK_HALF_PERIOD_MS * 2 - 1; 

  assign green_blink_time_clk = CLK_KHZ * GREEN_BLINK_TIME_MS - 1;   

  always_ff @( posedge clk_i )
    begin
      if(srst_i)
        red_time_ms <= 2;
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

  logic end_green, end_red, end_red_yellow, end_yellow, end_green_blink, end_blink;
  
  always_ff @( posedge clk_i )
    if( srst_i )
      end_red <= 0;
    else
      end_red  <= ( state_cnt == (red_time_clk - 1));
  
  always_ff @( posedge clk_i )
    if( srst_i )
      end_red_yellow <= 0;
    else
      end_red_yellow  <= ( state_cnt == (red_yellow_time_clk - 1));

  always_ff @( posedge clk_i )
    if( srst_i )
      end_green <= 0;
    else
      end_green  <= ( state_cnt == (green_time_clk - 1));
  
  always_ff @( posedge clk_i )
    if( srst_i )
      end_yellow <= 0;
    else
      end_yellow  <= ( state_cnt == (yellow_time_clk - 1));
  
  always_ff @( posedge clk_i )
    if( srst_i )
      end_green_blink <= 0;
    else
      end_green_blink  <= ( state_cnt == (green_blink_time_clk - 1));

  always_ff @( posedge clk_i )
    if( srst_i )
      end_blink <= 0;
    else
      end_blink  <= ( blink_state_cnt == (blink_state_clk - 1));

  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        state_cnt <= 0;
      else
        case(state)
          RED_S:             state_cnt <= ( end_red )         ? '0 : state_cnt + 1'b1;
          GREEN_S:           state_cnt <= ( end_green )       ? '0 : state_cnt + 1'b1;
          YELLOW_S:          state_cnt <= ( end_yellow )      ? '0 : state_cnt + 1'b1;
          RED_YELLOW_S:      state_cnt <= ( end_red_yellow )  ? '0 : state_cnt + 1'b1;
          OFF_S:             state_cnt <= 0;
          YELLOW_BLINK_S:    state_cnt <= 0;
          GREEN_BLINK_S:     state_cnt <= ( end_green_blink ) ? '0 : state_cnt + 1'b1;
        endcase
    end
  
  always_ff @( posedge clk_i )
    begin
      if( srst_i )
        blink_state_cnt <= 0;
      else
        begin
          case(state)
            RED_S:          blink_state_cnt <= 0;
            GREEN_S:        blink_state_cnt <= 0;
            YELLOW_S:       blink_state_cnt <= 0;
            RED_YELLOW_S:   blink_state_cnt <= 0;
            OFF_S:          blink_state_cnt <= 0;
            YELLOW_BLINK_S: blink_state_cnt <= ( end_blink ) ? '0 : blink_state_cnt + 1'b1;
            GREEN_BLINK_S:
              begin
                if(cmd_valid_i && cmd_type_i == 3'b010 )
                  blink_state_cnt <= 0;
                else
                  blink_state_cnt <= ( end_blink ) ? '0 : blink_state_cnt + 1'b1;
              end
          endcase
        end
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
            //$display("time is %d, cnt is %d", $time(), state_cnt);
            if(end_red)
              next_state = RED_YELLOW_S;
          end

        RED_YELLOW_S:
          begin
            if(end_red_yellow)
              next_state = GREEN_S;
          end

        GREEN_S:
          begin
            if(end_green)
              if(BLINK_GREEN_TIME_TICK != 0)
                next_state = GREEN_BLINK_S;
              else
                next_state = YELLOW_S;
          end

        GREEN_BLINK_S:
          begin
            if(end_green_blink)
              next_state = YELLOW_S;
          end

        YELLOW_S:
          begin
            if(end_yellow)
              next_state = RED_S;
          end

        YELLOW_BLINK_S:
          begin
            if(cmd_valid_i && cmd_type_i == 3'b000)
              next_state = RED_S;
          end

        default:
          begin
            next_state = OFF_S;
          end

      endcase
      if(cmd_valid_i && cmd_type_i == 3'b001)
        next_state = OFF_S;
      if(state != OFF_S && cmd_valid_i && cmd_type_i == 3'b010)
        next_state = YELLOW_BLINK_S;
    end

  always_comb
    begin
      green_o  = 0;
      case( state )
        GREEN_S:
          green_o  = 1;

        GREEN_BLINK_S:
          if(2 * blink_state_cnt >= blink_state_clk)
            green_o  = 1;

        default:
          green_o  = 0;

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
          if(2 * blink_state_cnt >= blink_state_clk)
            yellow_o = 1;
        
        default:
          yellow_o = 0;

      endcase
    end

  always_comb
    begin
      red_o  = 0;
      case( state )

        RED_S:
          red_o = 1;

        RED_YELLOW_S:
          red_o = 1;
      
        default:
          red_o = 0;

      endcase
    end

endmodule