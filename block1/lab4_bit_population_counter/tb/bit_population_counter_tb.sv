module bit_population_counter_tb #(
  parameter WIDTH = 3
);

  logic                       clk;
  logic                       srst;
  logic  [(WIDTH-1):0]        data;
  logic                       data_val_i;

  logic [$clog2(WIDTH) + 1:0] data_o;
  logic                       data_val_o;

  bit_population_counter#(WIDTH) priority_encoder_obj(
    .clk_i(clk),
    .srst_i(srst),
    .data_i(data),
    .data_val_i(data_val_i),

    .data_o(data_o),
    .data_val_o(data_val_o)
  );

  mailbox mbx;
  default clocking cb @( posedge clk );
  endclocking

  function automatic logic [(WIDTH-1):0] get_how_many_one(input logic [(WIDTH-1):0] local_val);
    logic [(WIDTH-1):0] ret = 0;
    for(int i = 0; i < WIDTH;i++)
      if(local_val[i] == 1)
        ret = ret + 1;
    return ret;
  endfunction

  task generate_value(
    logic [(WIDTH-1):0] input_data,
    logic rand_data_flag
  );
    automatic int time_to_ans;
    time_to_ans = 0;
    if(rand_data_flag)
      input_data = $urandom();

    data <= input_data;
    data_val_i <= 1;
    //$display("i put %b", input_data);
    mbx.put(input_data);
    ##1;
    data_val_i <= 0;
    while(!data_val_o)
      begin
        time_to_ans = time_to_ans + 1;
        ##1;
      end
    //$display("clk to get value %d", time_to_ans);
  endtask


  task check_value();
    logic [$clog2(WIDTH) + 1:0] reference_val;
    logic [(WIDTH-1):0] input_data;
    forever
      begin
        if(data_val_o)
          begin
            if(!mbx.try_get(input_data))
              begin
                $error("try to get value from empty, queue, check data_val_o wave");
                $stop();
              end
            reference_val = get_how_many_one(input_data);
            //$display("start test with data %b, ref val is %b", input_data, reference_val);

            if(!(data_o === reference_val))
              begin
                $error("dismatch right value get %b, requires %b", data_o, reference_val);
                $stop();
              end

            $display("successful test with data %b", input_data);
          end
        ##1;
      end
  endtask

  initial
    begin
      clk = 0;
      forever #5 clk = !clk;
    end

  task make_srst();
    ##1;
    srst <= 1'b1;
    ##1;
    srst <= 1'b0;
  endtask

  initial
    begin

      mbx = new();
      make_srst();
      fork
        check_value();
      join_none

      generate_value('0, 0);
      generate_value('1, 0);
      repeat(100) generate_value('0, 1);
      ##40;
      if( mbx.num() != 0 )
        begin
          $error("Have bits in referance queues!");
          $stop();
        end
      $stop();
    end

endmodule