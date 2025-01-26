module fifo #(
  parameter DWIDTH             = 4,
  parameter AWIDTH             = 3,
  parameter SHOWAHEAD          = 1,
  parameter ALMOST_FULL_VALUE  = 6,
  parameter ALMOST_EMPTY_VALUE = 2,
  parameter REGISTER_OUTPUT    = 0
)(
  input               clk_i,

  input               srst_i,
  input [DWIDTH-1:0]  data_i,
  input               wrreq_i,
  input               rdreq_i,

  output logic [DWIDTH-1:0] q_o,
  output logic              empty_o,
  output logic              full_o,
  output logic [AWIDTH:0]   usedw_o,
  output logic              almost_full_o,
  output logic              almost_empty_o
);

  logic[$clog2((2 ** AWIDTH) + 1):0] read_ind = '0;
  logic[$clog2((2 ** AWIDTH) + 1):0] write_ind = '0;

  logic[$clog2((2 ** AWIDTH) + 1):0] read_ind2;
  logic [DWIDTH-1:0] q_o2;

  memory #(
  .DWIDTH ( DWIDTH ),
  .AWIDTH ( (2 ** AWIDTH) + 1 )
  ) memory_block (
    .clk_i            (clk_i),

    .data_write_i     (data_i),
    .data_write_ind_i (write_ind),
    .wrreq_i          (wrreq_i),

    .data_read_ind_i  (read_ind2),
    .rdreq_i          (1),

    .readen_out       (q_o2)
  );

  always_ff @(posedge clk_i)
    begin
      if(srst_i == 1)
        begin
          read_ind <= '0;
        end
      else
        begin
          if(rdreq_i)
            if(read_ind != (2 ** AWIDTH))
              read_ind <= read_ind + 1;
            else
              read_ind <= '0;
        end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i == 1)
        begin
          write_ind <= '0;
        end
      else
        begin
          if(wrreq_i)
            if(write_ind != (2 ** AWIDTH))
              write_ind <= write_ind + 1;
            else
              write_ind <= '0;
        end
    end

  always_comb
    begin
      if(!rdreq_i)
        read_ind2 = (read_ind);
      else
        read_ind2 = (read_ind + 1);
    end

  always_comb
    begin
      if(empty_o)
        q_o = '0;
      else
        q_o = q_o2;
    end

  always_comb
    begin
      full_o = (read_ind + 1 == write_ind);
    end
  
  always_comb
    begin
      empty_o = (read_ind == write_ind);
    end

endmodule