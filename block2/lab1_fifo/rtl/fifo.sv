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

  int last_el, ind;
  logic[(1 << AWIDTH):0][DWIDTH - 1:0] data = '0;

  always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          last_el <= (1 << AWIDTH);
        end
      else
        begin
          //$display("%d", {wrreq_i, rdreq_i});
          case({wrreq_i, rdreq_i})
            1: last_el <= last_el + 1;
            2: last_el <= last_el - 1;
          endcase
        end
    end

    always_ff @(posedge clk_i)
    begin
      if(srst_i)
        begin
          for(int ind = (1 << AWIDTH); ind >= 0; ind--)
            begin
              data[ind] <= '0;
            end
        end
      else
        begin
          case({wrreq_i, rdreq_i})
            1:
              begin
                for(int ind = (1 << AWIDTH); ind >= 1; ind--)
                  begin
                    $display("ind %d, el %d", ind, data[ind - 1]);
                    data[ind] <= data[ind - 1];
                  end
              end
            2:
              begin
                $display("ind %d, el %d", last_el, data_i);
                data[last_el] <= data_i;
              end
            3:
              begin
                for(int ind = (1 << AWIDTH); ind >= 1; ind++)
                  begin
                    data[ind] <= data[ind - 1];
                  end
                data[last_el + 1] <= data_i;
              end
          endcase
        end
    end

  always_comb
    begin
      q_o = data[(1 << AWIDTH)];
    end
  
  always_comb
    begin
      empty_o = (last_el == (1 << AWIDTH));
    end
  
  always_comb
    begin
      full_o = (last_el == 0);
    end

  always_comb
    begin
      usedw_o = ((1 << AWIDTH) - last_el);
    end
  
  always_comb
    begin
      almost_full_o = (((1 << AWIDTH) - last_el) > ALMOST_FULL_VALUE);
    end

  always_comb
    begin
      almost_empty_o = (((1 << AWIDTH) - last_el) < ALMOST_EMPTY_VALUE);
    end


  

endmodule