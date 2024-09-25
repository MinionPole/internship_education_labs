module debouncer_top #(
  parameter CLK_FREQ_MHZ = 200,
  parameter GLITCH_TIME_NS = 20
)(
  input                       clk_150mhz,
  input                       key_i,

  output logic                key_pressed_stb_o
);
  logic                       key_reg;

  logic                       key_pressed_stb_reg;

  always_ff @( posedge clk_150mhz )
    begin
      key_reg                     <= key_i;

      key_pressed_stb_o           <= key_pressed_stb_reg;
    end

  debouncer#(
    .CLK_FREQ_MHZ       (CLK_FREQ_MHZ   ),
    .GLITCH_TIME_NS     (GLITCH_TIME_NS )
  ) debouncer_obj (
    .clk_i              (clk_150mhz     ),
    .key_i              (key_reg        ),

    .key_pressed_stb_o  (key_pressed_stb_reg)
  );


endmodule