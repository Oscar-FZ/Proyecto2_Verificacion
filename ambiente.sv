`timescale 1ns/1ps
`default_nettype none
`include "Router_library.sv"
`include "transactions.sv"
`include "driver_monitor.sv"

module ambiente_TB();
	parameter pckg_sz = 32;
	parameter fifo_depth = 4;
	parameter bdcst = {8{1'b1}};
	parameter ROWS = 4;
	parameter COLUMS = 4;

	bit clk;

	strt_drvr_mntr #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) driver_monitor_inst;

	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_drvr_mbx[ROWS*2+COLUMS*2];

	mesh_if #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) _if (.clk(clk));
	always #(1) clk = ~clk;



	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) trans[5];


	mesh_gnrtr #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) mesh_DUT
	(
		.clk			(_if.clk),
		.reset			(_if.reset),
		.pndng			(_if.pndng),
		.data_out		(_if.data_out),
		.popin			(_if.popin),
		.pop			(_if.pop),
		.data_out_i_in	(_if.data_out_i_in),
		.pndng_i_in		(_if.pndng_i_in)
	);


	initial begin
		clk = 0;

		for(int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			agnt_drvr_mbx[i] = new();
		end

		driver_monitor_inst = new();

		for(int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			driver_monitor_inst.drvr_mntr_hijo[i].fifo_hijo.vif = _if;
			driver_monitor_inst.drvr_mntr_hijo[i].agnt_drvr_mbx[i] = agnt_drvr_mbx[i];
			#2;
		end

		_if.reset = 1;
		#2;
		_if.reset = 0;
		
		trans[0] = new(.t_row_n(4'h4), .t_col_n(4'h5), .mode_n(1'b1), .pyld_n(15'b1010_1010_1010_101), .dir_env_n(8'h01));
		#2;
		trans[0].crea_paquetes();
		#2;
		agnt_drvr_mbx[0].put(trans[0]);
		
		trans[1] = new(.t_row_n(4'h5), .t_col_n(4'h4), .mode_n(1'b0), .pyld_n(15'b0101_0101_0101_010), .dir_env_n(8'h02));
		#2;
		trans[1].crea_paquetes();
		#2;
		agnt_drvr_mbx[1].put(trans[1]);

		trans[2] = new(.t_row_n(4'h3), .t_col_n(4'h5), .mode_n(1'b1), .pyld_n(15'b1100_1100_1100_110), .dir_env_n(8'h03));
		#2;
		trans[2].crea_paquetes();
		#2;
		agnt_drvr_mbx[2].put(trans[2]);

		trans[3] = new(.t_row_n(4'h5), .t_col_n(4'h3), .mode_n(1'b0), .pyld_n(15'b0011_0011_0011_001), .dir_env_n(8'h04));
		#2;
		trans[3].crea_paquetes();
		#2;
		agnt_drvr_mbx[3].put(trans[3]);

		trans[4] = new(.t_row_n(4'h2), .t_col_n(4'h5), .mode_n(1'b1), .pyld_n(15'b1111_1111_1111_111), .dir_env_n(8'h10));
		#2;
		trans[4].crea_paquetes();
		#2;
		agnt_drvr_mbx[4].put(trans[4]);

		fork
			driver_monitor_inst.start_driver();
			driver_monitor_inst.start_monitor();
		join_none


		#2000;
		$display("FIN");
		$finish;
	end
endmodule
