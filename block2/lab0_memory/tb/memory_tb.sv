module memory_tb#(
  parameter DWIDTH             = 4,
  parameter AWIDTH             = 8
);

  bit clk  = 1'b0;

  logic                     srst;
  logic [DWIDTH-1:0]        data_write;
  logic [$clog2(AWIDTH):0]  data_write_ind;
  logic                     wrreq;
  logic [$clog2(AWIDTH):0]  data_read_ind;
  logic                     rdreq;

  logic [DWIDTH-1:0] readen_out;

  memory#(
    .DWIDTH                ( DWIDTH           ),
    .AWIDTH                ( AWIDTH           )
  ) memory_dut (
    .clk_i                 (clk               ),
    .srst_i                (srst              ),
    .data_write_i          (data_write        ),
    .data_write_ind_i      (data_write_ind    ),
    .wrreq_i               (wrreq             ),
    .data_read_ind_i       (data_read_ind     ),
    .rdreq_i               (rdreq             ),

    .readen_out            (readen_out        )
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

  task add_data(
    input int write_flag,
    input int write_ind,
    input int write_data,

    input int read_flag,
    input int read_ind
    );
      if(write_flag)
        begin
          data_write     <= write_data;
          data_write_ind <= write_ind;
          wrreq          <= 1;
        end
      
      if(read_flag)
        begin
          data_read_ind  <= read_ind;
          rdreq          <= 1;
        end

      ##1;
      if(write_flag)
        begin
          wrreq <= 0;
        end
      
      if(read_flag)
        begin
          rdreq          <= 0;
        end
  endtask

  initial
  begin

    make_srst();
    ##1;
    add_data(1, 0, 1, 0, 0);
    add_data(1, 1, 2, 1, 0);
    add_data(1, 2, 3, 1, 2);
    add_data(0, 0, 0, 1, 2);
    ##5;
    $display("all test succed");
    $stop();
  end



endmodule