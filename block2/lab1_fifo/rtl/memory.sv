module memory #(
  parameter DWIDTH             = 4,
  parameter AWIDTH             = 1024
)(
  input                     clk_i,

  input [DWIDTH-1:0]        data_write_i,
  input [$clog2(AWIDTH):0]  data_write_ind_i,
  input                     wrreq_i,
  input [$clog2(AWIDTH):0]  data_read_ind_i,
  input                     rdreq_i,

  output logic [DWIDTH-1:0] readen_out
);

  logic[AWIDTH - 1:0][DWIDTH - 1:0] data;

  always_ff @(posedge clk_i)
    begin
      if(wrreq_i)
        begin
          data[data_write_ind_i] <= data_write_i;
        end
    end

  always_ff @(posedge clk_i)
    begin
      if(rdreq_i)
        readen_out <= data[data_read_ind_i];
    end

endmodule