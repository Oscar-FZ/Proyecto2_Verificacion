`timescale 1ns/1ps
`default_nettype none
`include "Router_library.sv"
`include "transactions.sv"
`include "driver_monitor.sv"
`include "agent.sv"
`include "checker.sv"

module ambiente_TB();
	parameter pckg_sz = 32;
	parameter fifo_depth = 4;
	parameter bdcst = {8{1'b1}};
	parameter ROWS = 4;
	parameter COLUMS = 4;

	bit clk;

	strt_drvr_mntr #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) driver_monitor_inst;
	agent #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agent_inst;
	checker_p #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) checker_inst;

	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_drvr_mbx[ROWS*2+COLUMS*2];
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_chkr_mbx;
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) mntr_chkr_mbx;
	sb_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) chkr_sb_mbx;
	instr_pckg_mbx test_agnt_mbx;

	instrucciones tipo;

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
		agnt_chkr_mbx = new();
		mntr_chkr_mbx = new();
		chkr_sb_mbx = new();
		test_agnt_mbx = new();

		checker_inst = new();
		agent_inst = new();
		driver_monitor_inst = new();

		for(int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			driver_monitor_inst.drvr_mntr_hijo[i].fifo_hijo.vif = _if;
			driver_monitor_inst.drvr_mntr_hijo[i].agnt_drvr_mbx[i] = agnt_drvr_mbx[i];
			agent_inst.agnt_drvr_mbx[i] = agnt_drvr_mbx[i];
			driver_monitor_inst.drvr_mntr_hijo[i].mntr_chkr_mbx = mntr_chkr_mbx;
			#2;
		end

		agent_inst.test_agnt_mbx = test_agnt_mbx;
		agent_inst.agnt_chkr_mbx = agnt_chkr_mbx;
		checker_inst.agnt_chkr_mbx = agnt_chkr_mbx;
		checker_inst.mntr_chkr_mbx = mntr_chkr_mbx;
		checker_inst.chkr_sb_mbx = chkr_sb_mbx;

		agent_inst.num_trans = 30;
		agent_inst.max_retardo_agnt = 20;
		tipo = aleatorio;
		test_agnt_mbx.put(tipo);

		_if.reset = 1;
		#2;
		_if.reset = 0;

		fork
			driver_monitor_inst.start_driver();
			driver_monitor_inst.start_monitor();
			agent_inst.run();
			checker_inst.update();
			checker_inst.check();
		join_none


		#2000;
		$display("FIN");
		$finish;
	end
endmodule
