module serializer_tb;

bit clk  = 1'b0;
bit srst = 1'b0;

initial begin
  forever #10 clk = ~clk;
end


default clocking cb @( posedge clk );
endclocking

task make_srst();
  ##1;
  srst <= 1'b1;
  ##2;
  srst <= 1'b0;
endtask

mailbox ref_bit_queue;
mailbox bit_queue;

logic [15:0] data_i     = '0;
logic [3:0]  data_mod_i = '0;
logic        data_val_i = 1'b0;
logic        ser_data;
logic        ser_val;
logic        busy;


task create_trans( bit rand_mod = 1'b1, bit [4:0] _mod = '0 );
  logic [15:0] data;
  logic [4:0]  mod;

  if( !rand_mod && ( _mod == 0 ) )
    $warning( "_mod must be in range 1..16, not %2d! Do nothing %m.", _mod );

  data = $urandom();
  mod  = ( rand_mod ) ? $urandom_range( 1,16 ) : _mod;

  if( mod > 2 )
    for( int i = 0; i < mod; i++ )
      ref_bit_queue.put( data[15-i] );

  do
    ##1;
  while( busy );
  data_i     <= data;
  data_mod_i <= mod[3:0];
  data_val_i <= 1'b1;
  ##1;
  data_val_i <= 1'b0;
  data_i     <= 'x;
endtask

task checkd();
  logic _ref;

  forever
    begin
      if( ser_val === 1'b1 )
      begin
          ref_bit_queue.get( _ref );
          if( _ref !== ser_data )
            begin
              $error( "Wrong data 0x%d 0x%d!", _ref, ser_data );
              $stop();
            end
      end
      ##1;
    end

endtask


task accumd();
  bit ref_bit;
  forever
    begin
      if( ser_val === 1'b1 )
        bit_queue.put( ser_data );
      ##1;
    end
endtask

initial
  begin
    bit_queue     = new();
    ref_bit_queue = new();

    make_srst();
    repeat ( 40 ) ##1;

    fork
      checkd();
    join_none
    for( int i = 1; i < 16; i++ )
      create_trans( 1'b0, i );
    repeat (10) create_trans( 1'b0, 16);
    repeat (10) create_trans( 1'b0, 1 );
    repeat (10) create_trans( 1'b0, 2 );
    repeat (800) create_trans( 1'b1, 0 );
    repeat ( 40 ) ##1;
    if( ref_bit_queue.num() != 0 )
      begin
        $error("Have bits in referance queues %d!", ref_bit_queue.num() );
        $stop();
      end
    if( bit_queue.num() != 0 )
      begin
        $error("Have extra output bits %d!", bit_queue.num());
        $stop();
      end
    $display("End of simulation, no errors.");
    $stop();
  end

serializer DUT(
  .clk_i          ( clk          ),
  .srst_i         ( srst         ),

  .data_i         ( data_i       ),
  .data_mod_i     ( data_mod_i   ),
  .data_val_i     ( data_val_i   ),

  .ser_data_o     ( ser_data     ),
  .ser_data_val_o ( ser_val      ),

  .busy_o         ( busy         )
);


endmodule