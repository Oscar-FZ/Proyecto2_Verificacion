//`include "fifo.sv"
//`include "Library.sv"
`include "Router_library.sv"


module prueba_tb();
	parameter pckg_sz = 32;
	parameter fifo_depth = 8;
	parameter broadcast = {8{1'b1}};
	parameter ROWS = 4;
	parameter COLUMS = 4;

	bit clk;
	bit rst;

	bit [pckg_sz-1:0] data_final [ROWS*2+COLUMS*2];

	bit pndng [ROWS*2+COLUMS*2];							//out
	bit [pckg_sz-1:0] data_out [ROWS*2+COLUMS*2]; 		//out
	bit popin [ROWS*2+COLUMS*2]; 							//out
	bit pop [ROWS*2+COLUMS*2]; 							//in
	bit [pckg_sz-1:0] data_out_i_in [ROWS*2+COLUMS*2];	//in
	bit pndng_i_in [ROWS*2+COLUMS*2]; 					//in

	mesh_gnrtr #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(broadcast)) dut 
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

	task nose();
		forever begin
			@(posedge clk);
			if (popin[0] == 1) begin
				pndng_i_in[0] = 1'b0;
				//pop[0] = 1'b1;
				//data_final[0] = data_out[15];
				data_out_i_in[0] = 'b0;

				//data_out.pop_back();
				//$display("[DEBUG] Dato enviado! %h:",data_final[0]);
				//break;
			end

			if (pndng[15] == 1'b1) begin
				pop[0] = 1'b1;
				break;
			end

			//else $display("[DEBUG] enviando dato");
		end
	endtask


	initial begin
		clk = 0;
		rst = 1;
		#2;
		rst = 0;
		#2;
		data_out_i_in[0] = 32'b00000000_0100_0101_1_10101010_0101010;
		pndng_i_in[0] = 1'b1; 
		while(popin[0] == 1'b0) begin
			#1;
		end
		pndng_i_in[0] = 1'b0;
		while(pndng[15] == 0) #1;
		pop[15] = 1'b1;
		#2000;
		$finish;
	end
endmodule
