module traffic_lights_top #(
  parameter BLINK_HALF_PERIOD_MS  = 4,
  parameter BLINK_GREEN_TIME_TICK = 0,
  parameter RED_YELLOW_MS         = 10
)(
  input                       clk_2000hz,

  input                       srst_i,
  input [2:0]                 cmd_type_i,
  input                       cmd_valid_i,
  input [15:0]                cmd_data_i,

  output logic                red_o,
  output logic                yellow_o,
  output logic                green_o

);

  logic                       srst_reg;
  logic [2:0]                 cmd_type_i_reg;
  logic                       cmd_valid_i_reg;
  logic [15:0]                cmd_data_i_reg;

  logic                 red_o_reg;
  logic                 yellow_o_reg;
  logic                 green_o_reg;

  always_ff @( posedge clk_2000hz )
  begin
    srst_reg        <= srst_i;
    cmd_type_i_reg  <= cmd_type_i;
    cmd_valid_i_reg <= cmd_valid_i;
    cmd_data_i_reg  <= cmd_data_i;

    red_o           <= red_o_reg;
    yellow_o        <= yellow_o_reg;
    green_o         <= green_o_reg;
  end

  traffic_lights#(
    .BLINK_HALF_PERIOD_MS      ( BLINK_HALF_PERIOD_MS ),
    .BLINK_GREEN_TIME_TICK     ( BLINK_GREEN_TIME_TICK),
    .RED_YELLOW_MS             ( RED_YELLOW_MS        )
  ) traffic_lights_obj (
    .clk_i                     (clk_2000hz            ),
    .srst_i                    (srst_reg              ),
    .cmd_type_i                (cmd_type_i_reg        ),
    .cmd_valid_i               (cmd_valid_i_reg       ),
    .cmd_data_i                (cmd_data_i_reg        ),

    .red_o                     (red_o_reg             ),
    .yellow_o                  (yellow_o_reg          ),
    .green_o                   (green_o_reg           )
  );




endmodule