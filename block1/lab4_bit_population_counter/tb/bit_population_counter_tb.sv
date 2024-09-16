module bit_population_counter_tb #(
  parameter WIDTH = 128
);

  logic                       clk;
  logic                       srst;
  logic  [(WIDTH-1):0]        data;
  logic                       data_val_i;

  logic [$clog2(WIDTH) + 1:0] data_o;
  logic                       data_val_o;

  bit_population_counter#(
    .WIDTH (WIDTH)
  ) priority_encoder_obj(
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


  task generate_value(
    logic [(WIDTH-1):0] input_data,
    logic rand_data_flag,
    int delay,
    logic rand_delay_flag
  );
    automatic int time_to_ans;
    ##1
    time_to_ans = 0;
    data_val_i <= 0;
    if( rand_delay_flag )
      delay = ($urandom() % 20);
    for( int i = 0; i < delay; i++ )
      ##1;

    if( rand_data_flag )
      for( int i = 0; i <= WIDTH / 32; i++ )
        begin
          input_data = input_data << 32;
          input_data[31:0] = $urandom();
        end
    data <= input_data;
    data_val_i <= 1;
    //$display("i put %b", input_data);
    mbx.put(input_data);
    //$display("clk to get value %d", time_to_ans);
  endtask


  task check_value();
    logic [$clog2(WIDTH) + 1:0] reference_val;
    logic [(WIDTH-1):0] input_data;
    forever
      begin
        if( data_val_o )
          begin
            if( !mbx.try_get(input_data) )
              begin
                $error("try to get value from empty, queue, check data_val_o wave");
                $stop();
              end
            reference_val = $countones(input_data);
            //$display("start test with data %b, ref val is %b", input_data, reference_val);

            if( !(data_o === reference_val) )
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

      generate_value('0, 0, 0, 0);
      generate_value('1, 0, 0, 0);
      repeat(100) generate_value('0, 1, 0, 0);
      repeat(100) generate_value('0, 1, 10, 1);
      //repeat(100) generate_value('0, 1, 20, 1);
      ##1
      // stop send data
      data_val_i <= 0;
      ##40;
      if( mbx.num() != 0 )
        begin
          $error("Have bits in referance queues!");
          $stop();
        end
      $display("all tests success");
      $stop();
    end

endmodule