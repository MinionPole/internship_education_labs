`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.08.2024 20:07:36
// Design Name: 
// Module Name: serilializator_tb1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module serilializator_tb1;
bit clk;
bit reset;

logic[15:0] data_i;
logic[3:0] data_mod_i;
logic data_valid; 

logic ser_data_o; 
logic ser_data_val_o; 
logic busy_ota_o; 


serializator ser_obj(
    .clk_i(clk),
    .srst_i(reset),
    
    .data_i(data_i),
    .data_mod_i(data_mod_i),
    .data_val_i(data_valid),
    
    .ser_data_o(ser_data_o),
    .ser_data_val_o(ser_data_val_o),
    .busy_o(busy_ota_o)
    );
    
initial 
  forever
    #5 clk = !clk;
    
int i;

initial 
  begin
    $display("initializing");
    reset       <= 1;
    @(posedge clk)
    reset       <= 0;
    @(posedge clk)
    data_i      <= 16'b1011000000000000;
    data_mod_i  <= 4'd6;
    data_valid  <= 1;
    @(posedge clk)
    data_valid  <= 0;


    $display("first_test");
    for( i = 0;i < 4;i = i + 1 )
    begin
        @(posedge clk)
        #1
        if( ser_data_o != data_i[15-i] )
        begin
            $display("error, wrong data out on first cycle in %d el, need = %b, get = %b", i, data_i[15-i], ser_data_val_o);
        end
        
        if( busy_ota_o != 1 )
        begin
            $display("error, must be busy on first cycle in %d el", i);
        end
        
        if( ser_data_val_o != 1 )
        begin
            $display("error, must be correct data_flag on first cycle in %d el", i);
        end
    end
    
    #100
    @(posedge clk)
    data_i      <= 16'b1011000000000101;
    data_mod_i  <= 4'd0;
    data_valid  <= 1;
    @(posedge clk)
    data_valid  <= 0;
    $display("second_test");
    for(i = 0;i < 15;i = i + 1)
    begin
        @(posedge clk)
        #1
        if( ser_data_o != data_i[15-i] )
        begin
            $display("error, wrong data out on first cycle in %d el, need = %b, get = %b", i, data_i[15-i], ser_data_val_o);
        end
        
        if( busy_ota_o != 1 )
        begin
            $display("error, must be busy on first cycle in %d el", i);
        end
        
        if( ser_data_val_o != 1 )
        begin
            $display("error, must be correct data_flag on first cycle in %d el", i);
        end
        
    end
    #10
    $display("forbidden inputs check");    
    
    @(posedge clk)
    data_i      <= 16'b1011000000000101;
    data_mod_i  <= 4'd1;
    data_valid  <= 1;
    @(posedge clk)
    if( busy_ota_o == 1 )
      begin
        $display("error, you shouldn't print 1 bit");
      end
    
    @(posedge clk)
    data_mod_i  <= 4'd2;
    if( busy_ota_o == 1 )
      begin
        $display("error, you shouldn't print 1 bit");
      end  
    
    @(posedge clk)  
    data_i      <= 16'b1011000000000101;
    data_mod_i  <= 4'd0;
    data_valid  <= 1;
    
    #75
    reset       <= 1;
    @(posedge clk)
	 // waiting reset
    @(posedge clk)
    if( busy_ota_o == 1 )
      begin
        $display("wrong reset");
      end  
      
  end


endmodule
