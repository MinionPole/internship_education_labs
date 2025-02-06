module fifo #(
  parameter DWIDTH             = 4,
  parameter AWIDTH             = 7,
  parameter SHOWAHEAD          = 1,
  parameter ALMOST_FULL_VALUE  = 6,
  parameter ALMOST_EMPTY_VALUE = 2,
  parameter REGISTER_OUTPUT    = 0
)(
  input                     clk_i,

  input                     srst_i,
  input [DWIDTH-1:0]        data_i,
  input                     wrreq_i,
  input                     rdreq_i,

  output logic [DWIDTH-1:0] q_o,
  output logic              empty_o,
  output logic              full_o,
  output logic [AWIDTH:0]   usedw_o,
  output logic              almost_full_o,
  output logic              almost_empty_o
);

  logic [(AWIDTH):0] read_ind;
  logic [(AWIDTH):0] write_ind;
  logic [AWIDTH:0]                    size;
  logic [DWIDTH-1:0] q_o2;

  // on rdreq_i flag we need already read from the future el
  logic[(AWIDTH):0] read_ind_memory;

  logic writen_to_empty;

  logic  read_allow;
  assign read_allow      = (rdreq_i || (writen_to_empty));
  //assign almost_empty_o  = (size < ALMOST_EMPTY_VALUE);

  memory #(
  .DWIDTH ( DWIDTH ),
  .AWIDTH ( AWIDTH + 1 )
  ) memory_block (
    .clk_i            (clk_i),

    .data_write_i     (data_i),
    .data_write_ind_i (write_ind),
    .wrreq_i          (wrreq_i),

    .data_read_ind_i  (read_ind_memory),
    .rdreq_i          (read_allow),

    .readen_out       (q_o2)
  );

  assign usedw_o = size;

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          almost_full_o <= '0;
        end
      else
        begin
          if(rdreq_i && !wrreq_i)
            almost_full_o <= (size - 1 >= ALMOST_FULL_VALUE);
          else
            if(!rdreq_i && wrreq_i)
              almost_full_o <= (size + 1 >= ALMOST_FULL_VALUE);
        end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          almost_empty_o <= '1;
        end
      else
        begin
          if(rdreq_i && !wrreq_i)
            almost_empty_o <= (size - 1 < ALMOST_EMPTY_VALUE);
          else
            if(!rdreq_i && wrreq_i)
              almost_empty_o <= (size + 1 < ALMOST_EMPTY_VALUE);
        end
    end
  
  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          read_ind <= '0;
        end
      else
        begin
          if(rdreq_i)
            if(read_ind != (1 << AWIDTH))
              read_ind <= read_ind + 1'b1;
            else
              read_ind <= '0;
        end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          write_ind <= '0;
        end
      else
        begin
          if(wrreq_i)
            if(write_ind != (1 << AWIDTH))
              write_ind <= write_ind + 1'b1;
            else
              write_ind <= '0;
        end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        size <= 0;
      else
        begin
          if(!rdreq_i && wrreq_i)
            size <= size + 1;
          else
            if(rdreq_i && !wrreq_i)
              size <= size - 1;
        end
    end

  always_comb
    begin
      if(!rdreq_i)
        read_ind_memory = (read_ind);
      else
        if(read_ind != (1 << AWIDTH))
          read_ind_memory = read_ind + 1'b1;
        else
          read_ind_memory = '0;
    end

  always_comb
    begin
      if(!((read_ind == write_ind || writen_to_empty)))
        q_o = q_o2;
      else
        q_o = '0;
    end
  
  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          full_o <= '0;
        end
      else
        begin
          if(size + 1 == (1 << AWIDTH) && wrreq_i && !rdreq_i)
            full_o <= 1'b1;
          else
            if(full_o && rdreq_i)
              full_o <= 1'b0;
        end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          writen_to_empty <= 0;
        end
      else
        begin
          writen_to_empty <= 0;
          if(size == 0)
            begin
              if(wrreq_i)
                writen_to_empty <= 1;
            end
          else
            if(size == 1)
              if(wrreq_i && rdreq_i)
                writen_to_empty <= 1;     
        end
    end

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        empty_o <= 1;
      else
        begin
          //empty_o <= 0;
          if(size == 0 && !wrreq_i && !rdreq_i)
            empty_o <= 1;
          else
            if(size == 0 && wrreq_i)
              empty_o <= 1;
            else
              if(size == 1 && rdreq_i)
                empty_o <= 1; 
              else
                empty_o <= 0; 
         end

    end
endmodule