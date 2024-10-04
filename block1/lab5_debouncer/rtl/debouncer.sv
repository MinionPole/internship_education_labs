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

  logic                       one_flag;
  logic [$clog2(LIMIT):0]     cnt;
  logic                       sync_out;
  
  synchronizer sync_obj (
    .clk          (clk_i    ),
    .signal       (key_i    ),

    .signal_sync  (sync_out )
  );

    always_ff @( posedge clk_i )
    begin
      if(!( cnt < LIMIT))
        one_flag <= 0;
      if( sync_out )
        one_flag <= 1;
    end

  always_ff @( posedge clk_i )
    begin
      if( !sync_out )
        cnt <= ( cnt < LIMIT ) ? cnt + 1 : 1; 
      else
        cnt <= 0;
    end

  always_ff @( posedge clk_i )
    begin
      key_pressed_stb_o <= ( !( cnt < LIMIT) && one_flag) ? 1'b1 : 1'b0;
    end


endmodule