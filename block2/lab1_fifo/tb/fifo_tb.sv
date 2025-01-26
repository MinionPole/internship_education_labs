module fifo_tb#(
  parameter DWIDTH             = 4,
  parameter AWIDTH             = 3,
  parameter SHOWAHEAD          = 1,
  parameter ALMOST_FULL_VALUE  = 6,
  parameter ALMOST_EMPTY_VALUE = 2,
  parameter REGISTER_OUTPUT    = 0
);

  bit clk  = 1'b0;

  logic               srst;
  logic [DWIDTH-1:0]  data_i  = '0;
  logic               wrreq_i = '0;
  logic               rdreq_i = '0;

  logic [DWIDTH-1:0] q_o1;
  logic [DWIDTH-1:0] q_o2;
  logic              empty_o1;
  logic              empty_o2;
  logic              full_o1;
  logic              full_o2;
  logic [AWIDTH:0]   usedw_o1;
  logic [$clog2(AWIDTH):0]   usedw_o2;
  logic              almost_full_o;
  logic              almost_empty_o;

  fifo#(
    .DWIDTH             ( DWIDTH ),
    .AWIDTH             ( AWIDTH),
    .SHOWAHEAD          ( SHOWAHEAD            ),
    .ALMOST_FULL_VALUE  ( ALMOST_FULL_VALUE    ),
    .ALMOST_EMPTY_VALUE ( ALMOST_EMPTY_VALUE   ),
    .REGISTER_OUTPUT    ( REGISTER_OUTPUT      )
  ) fifo_dut (
    .clk_i                 (clk               ),
    .srst_i                (srst              ),
    .data_i                (data_i            ),
    .wrreq_i               (wrreq_i           ),
    .rdreq_i               (rdreq_i           ),

    .q_o                   (q_o1              ),
    .empty_o               (empty_o1          ),
    .full_o                (full_o1           ),
    .usedw_o               (usedw_o1          ),
    .almost_full_o         (almost_full_o     ),
    .almost_empty_o        (almost_empty_o    )
  );

  scfifo #(
  .lpm_width ( DWIDTH ),
  .lpm_widthu ( AWIDTH ),
  .lpm_numwords ( 2 ** AWIDTH ),
  .lpm_showahead ( "ON" ),
  .lpm_type ( "scfifo" ),
  .lpm_hint ( "RAM_BLOCK_TYPE=M10K" ),
  .intended_device_family ( "Cyclone V" ),
  .underflow_checking ( "ON" ),
  .overflow_checking ( "ON" ),
  .allow_rwcycle_when_full ( "OFF" ),
  .use_eab ( "ON" ),
  .add_ram_output_register ( "OFF" ),
  .almost_full_value ( ALMOST_FULL_VALUE ),
  .almost_empty_value ( ALMOST_EMPTY_VALUE ),
  .maximum_depth ( 0 ),
  .enable_ecc ( "FALSE" )
  ) golden_model (
    .clock(clk),
    .data(data_i),
    .wrreq(wrreq_i),
    .rdreq(rdreq_i),
    .q(q_o2),
    .full(full_o2),
    .empty(empty_o2),
    .usedw(usedw_o2)
  );

  task make_srst();
    ##1;
    srst <= 1'b1;
    ##1;
    srst <= 1'b0;
  endtask

  initial begin
    forever #10 clk = ~clk;
  end

  default clocking cb @( posedge clk );
  endclocking

  task insert(input int a);
      data_i <= a;
      wrreq_i <= 1;
      ##1;
      wrreq_i <= 0;
  endtask

  task remove;
      rdreq_i <= 1;
      ##1;
      rdreq_i <= 0;
      $display("val is %d", q_o1);
  endtask

  task ins_plus_rem(input int a);
      ##1;
      data_i <= a;
      wrreq_i <= 1;
      rdreq_i <= 1;
      ##1;
      wrreq_i <= 0;
      rdreq_i <= 0;
  endtask


  task check_value();
  longint data_from_mbx;
    forever
      begin
        if(q_o1 != q_o2)
          begin
            $error("main outputs different");
            $stop();
          end
        /*if(full_o1 != full_o2)
          begin
            $error("full_flag outputs different");
            $stop();
          end
        if(empty_o1 != empty_o2)
          begin
            $error("empty_flag outputs different");
            $stop();
          end*/
        ##1;
      end
  endtask

  task generate_input();
    int desicion;
    automatic int value = '0;
    
    desicion = $urandom();
    case (desicion % 2)
        2'b00:
          begin
            //add
            if(!full_o2)
              begin
                value = $urandom();
                insert(value);
              end
          end
        2'b01:
          begin
            if(!empty_o2)
              begin
                remove();
              end
            //rem
          end
        2'b10:
          begin
            //add+rem
            if(!full_o2)
              begin
                value = $urandom();
                ins_plus_rem(value);
              end
          end
    endcase
    ##1;
  endtask


  initial
  begin

    make_srst();
    ##1;
    fork
      check_value();
    join_none
    insert(1);
    ##2
    remove();
    ##2;
    /*insert(3);
    insert(4);
    ins_plus_rem(6);
    ##5;
    repeat(500) generate_input();
    ##5;*/
    $display("all test succed");
    $stop();
  end



endmodule