module priority_encoder_tb#(parameter WIDTH = 3)();

    logic                clk;
    logic                srst;
    logic  [(WIDTH-1):0] data;
    logic                data_val_i;

    logic [(WIDTH-1):0]  data_left;
    logic [(WIDTH-1):0]  data_right;
    logic                data_val_o;

  priority_encoder#(WIDTH) priority_encoder_obj(
    .clk_i(clk),
    .srst_i(srst),
    .data_i(data),
    .data_val_i(data_val_i),

    .data_left_o(data_left),
    .data_right_o(data_right),
    .data_val_o(data_val_o)
  );

  mailbox mbx;
  int cnt = 0;
  default clocking cb @( posedge clk );
  endclocking

  task get_left_ans(
    input logic [(WIDTH-1):0] local_val,
    inout logic [(WIDTH-1):0] left_ans 
  );
    static int temp = 0;
    left_ans = '0;
    for(int i = 0; i < WIDTH;i++)
      begin
        if(local_val[i] == 1)
          begin
            left_ans[i] = 1;
            i = WIDTH;
          end
      end
    //$display("left ans is %b", left_ans);
  endtask

  task get_right_ans(
    input logic [(WIDTH-1):0] local_val,
    inout logic [(WIDTH-1):0] right_ans  
  );
    static int temp = 0;
    right_ans = '0;
    for(int i = WIDTH - 1; i >= 0;i--)
      begin
        if(local_val[i] == 1)
          begin
            right_ans[i] = 1;
            i = -1;
          end
      end
    //$display("right ans is %b", right_ans);
  endtask

  task generate_value(
    logic [(WIDTH-1):0] input_data,
    logic rand_data_flag
  );
    if(rand_data_flag)
      input_data = $urandom();
    
    data <= input_data;
    data_val_i <= 1;
    //$display("i put %b", input_data);
    mbx.put(input_data);
    ##1;
    data_val_i <= 0;
    if($urandom() % 10 == 0)
      ##1;
  endtask


  task check_value();
    logic [(WIDTH-1):0] local_val;
    logic [(WIDTH-1):0] left_ans;
    logic [(WIDTH-1):0] right_ans;
    static logic flag = 0;
    forever
      begin
        if(data_val_o)
          begin
            flag = 0;
            mbx.get(local_val);
            //$display("start test with data %b", local_val);
            get_left_ans(local_val, left_ans);
            get_right_ans(local_val, right_ans);
            if(!(left_ans === data_left))
              begin
                $error("dismatch left value get %b, requires %b", data_left, left_ans);
                $stop;
              end
              
            if(!(right_ans === data_right))
              begin
                $error("dismatch right value get %b, requires %b", data_right, right_ans);
                $stop;
              end

            $display("successful test with data %b", local_val);
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


      /*generate_value(000, 0);
      generate_value(001, 0); 
      generate_value(010, 0);
      generate_value(011, 0);
      generate_value(100, 0);
      generate_value(101, 0);
      generate_value(110, 0);
      generate_value(111, 0);*/    
      generate_value('0, 0);
      generate_value('1, 0);
      repeat(100) generate_value('0, 1);
      ##20;
      $stop;
    end

endmodule