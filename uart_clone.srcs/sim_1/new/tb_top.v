`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/13/2026 02:21:57 PM
// Design Name: 
// Module Name: tb_top
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


module tb_top(

    );
    reg				tb_clk, tb_rst;
    
    always
    begin : clk_gen
        #1 tb_clk = ~tb_clk;
    end
    
    //----------------------------------------------------------------
	// init_sim()
	//
	// Initialize all counters and testbed functionality as well
	// as setting the DUT inputs to defined values.
	//----------------------------------------------------------------
	task init_sim;
		begin
			tb_clk		= 0;
            tb_rst = 0;
		end
	endtask // init_sim()
    
    //----------------------------------------------------------------
	// reset_dut()
	//
	// Toggles reset to force the DUT into a well defined state.
	//----------------------------------------------------------------
	task reset_dut;
		begin
			$display("*** Toggling reset...");
			tb_rst = 1;
			#4;
			tb_rst = 0;
		end
	endtask // reset_dut()

    initial
  
    begin : top_test
        init_sim();
        reset_dut();
    end // top_test
    
    top dut (
        .CLK100MHZ(tb_clk),
        .btn(tb_rst),
        .led(),
        .uart_rxd_out(),
        .uart_txd_in()
    );
endmodule
