module debouncer #(
  parameter CLK_FREQ_MHZ = 150,
  parameter GLITCH_TIME_NS = 10
)(
  input                       clk_i,
  input                       key_i,

  output logic                key_pressed_stb_o
);
  // at least one tact button must be pressed
  localparam int LIMIT = (CLK_FREQ_MHZ * GLITCH_TIME_NS + 999) / 1000; 

  int cnt = 0;

  always_ff @( posedge clk_i )
    begin
      if( !key_i )
        cnt <= ( cnt < LIMIT ) ? cnt + 1 : 1; 
      else
        cnt <= 0; 
    end
 
  always_ff @( posedge clk_i )
    begin
      key_pressed_stb_o <= ( cnt == LIMIT ) ? 1'b1 : 1'b0;
    end


endmodule