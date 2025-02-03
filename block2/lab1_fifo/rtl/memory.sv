module memory #(
  parameter DWIDTH             = 4,
  parameter AWIDTH             = 8
)(
  input                     clk_i,

  input [DWIDTH-1:0]        data_write_i,
  input [AWIDTH-1:0]  data_write_ind_i,
  input                     wrreq_i,
  input [AWIDTH-1:0]  data_read_ind_i,
  input                     rdreq_i,

  output logic [DWIDTH-1:0] readen_out
);

  logic[DWIDTH - 1:0] data[(1 << AWIDTH) - 1:0];

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
        begin
          readen_out <= data[data_read_ind_i];
        end
    end

endmodule