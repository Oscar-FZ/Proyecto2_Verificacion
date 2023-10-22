`include "fifo.sv"
`include "Library.sv"
`include "Router_library.sv"


module prueba_tb();
	parameter pckg_sz = 16;
	parameter fifo_depth = 8;
	parameter broadcast = {8{1'b1}};
	parameter ROWS = 4;
	parameter COLUMS = 4;

	bit clk;
	bit rst;
	logic pndng [ROWS*2+COLUMS*2];							//out
	logic [pckg_sz-1:0] data_out [ROWS*2+COLUMS*2]; 		//out
	logic popin [ROWS*2+COLUMS*2]; 							//out
	logic pop [ROWS*2+COLUMS*2]; 							//in
	logic [pckg_sz-1:0] data_out_i_in [ROWS*2+COLUMS*2];	//in
	logic pndng_i_in [ROWS*2+COLUMS*2]; 					//in

	mesh_gnrtr #(.ROWNS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), fifo_depth(fifo_depth), .bdcst(broadcast)) dut 
	(
		.clk			(clk),
		.reset			(rst),
		.pndng			(pndng),
		.data_out		(data_out),
		.popin			(popin),
		.pop			(pop),
		.data_out_i_in	(data_out_i_in),
		.pndng_i_in		(pndng_i_in)
	);

	always #(1) clk=~clk;

	initial begin
		clk = 0;
		rst = 1;
		#1;
		rst = 0;

	end


endmodule
