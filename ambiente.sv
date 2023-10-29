`timescale 1ns/1ps
`default_nettype none
`include "Router_library.sv"
`include "transactions.sv"
`include "driver_monitor.sv"
`include "agent.sv"
`include "checker.sv"
`include "scoreboard.sv"

module ambiente_TB();
	parameter pckg_sz = 32;
	parameter fifo_depth = 8;
	parameter bdcst = {8{1'b1}};
	parameter ROWS = 4;
	parameter COLUMS = 4;

	bit clk;


	strt_drvr_mntr #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) driver_monitor_inst;
	agent #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agent_inst;
	checker_p #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) checker_inst;
	scoreboard #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) scoreboard_inst;

	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_drvr_mbx[ROWS*2+COLUMS*2];
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) drvr_chkr_mbx;
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) mntr_chkr_mbx;
	sb_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) chkr_sb_mbx;
	instr_pckg_mbx test_agnt_mbx;
	path_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) path_chkr_mbx;

	instrucciones tipo;

	mesh_if #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) _if (.clk(clk));
	always #(1) clk = ~clk;



	path_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) paths;


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
		drvr_chkr_mbx = new();
		mntr_chkr_mbx = new();
		chkr_sb_mbx = new();
		test_agnt_mbx = new();
		path_chkr_mbx = new();

		scoreboard_inst = new();
		checker_inst = new();
		agent_inst = new();
		driver_monitor_inst = new();
		paths = new();

		for(int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			driver_monitor_inst.drvr_mntr_hijo[i].fifo_hijo.vif = _if;
			driver_monitor_inst.drvr_mntr_hijo[i].agnt_drvr_mbx[i] = agnt_drvr_mbx[i];
			agent_inst.agnt_drvr_mbx[i] = agnt_drvr_mbx[i];
			driver_monitor_inst.drvr_mntr_hijo[i].mntr_chkr_mbx = mntr_chkr_mbx;
			driver_monitor_inst.drvr_mntr_hijo[i].drvr_chkr_mbx = drvr_chkr_mbx;
			#2;
		end

		agent_inst.test_agnt_mbx = test_agnt_mbx;
		//agent_inst.agnt_chkr_mbx = agnt_chkr_mbx;
		checker_inst.drvr_chkr_mbx = drvr_chkr_mbx;
		checker_inst.mntr_chkr_mbx = mntr_chkr_mbx;
		checker_inst.chkr_sb_mbx = chkr_sb_mbx;
		checker_inst.path_chkr_mbx = path_chkr_mbx;
		scoreboard_inst.chkr_sb_mbx = chkr_sb_mbx;

		agent_inst.num_trans = 50;
		agent_inst.max_retardo_agnt = 20;
		scoreboard_inst.num_trans = agent_inst.num_trans;
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
			checker_inst.update_path();
			save_path();
			scoreboard_inst.run();
		join_none

		#2000;
		$display("FIN");
		$finish;
	end

	task print_rc(int r = 1, int c = 1, p = 0);
		forever begin
			@(posedge _if.clk);
			//$display("adsads %d", mesh_DUT.pepe);
			if (mesh_DUT._rw_[1]._clm_[1].rtr._nu_[1].rtr_ntrfs_.pop) begin
				$display("[AMBIENTE] Row: %d Col: %d", mesh_DUT._rw_[1]._clm_[1].rtr._nu_[1].rtr_ntrfs_.id_r, mesh_DUT._rw_[1]._clm_[1].rtr._nu_[1].rtr_ntrfs_.id_c);
			end
			$display("[AMBIENTE] POP_CONNECTED %b", mesh_DUT._rw_[1]._clm_[1].pop_connected[1]);
			
		end
	endtask

	task save_path();
		forever begin
			@(posedge _if.clk);
			//ID 11
			if ({mesh_DUT._rw_[1]._clm_[1].pop_connected[0], mesh_DUT._rw_[1]._clm_[1].pop_connected[1], mesh_DUT._rw_[1]._clm_[1].pop_connected[2], mesh_DUT._rw_[1]._clm_[1].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[1]._clm_[1].pop_connected[0]) begin
                    paths.row = 1;
                    paths.colum = 1;
                    paths.paquete = mesh_DUT._rw_[1]._clm_[1].data_out_connected[0];
                    paths.print("[AMBIENTE]");
                    path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[1].pop_connected[1]) begin
                    paths.row = 1;
                    paths.colum = 1;
                    paths.paquete = mesh_DUT._rw_[1]._clm_[1].data_out_connected[1];
                    paths.print("[AMBIENTE]");
                    path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[1].pop_connected[2]) begin
                    paths.row = 1;
                    paths.colum = 1;
                    paths.paquete = mesh_DUT._rw_[1]._clm_[1].data_out_connected[2];
                    paths.print("[AMBIENTE]");
                    path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[1].pop_connected[3]) begin
                    paths.row = 1;
                    paths.colum = 1;
                    paths.paquete = mesh_DUT._rw_[1]._clm_[1].data_out_connected[3];
                    paths.print("[AMBIENTE]");
                    path_chkr_mbx.put(paths);
				end
			end
			
			//ID 12
			if ({mesh_DUT._rw_[1]._clm_[2].pop_connected[0], mesh_DUT._rw_[1]._clm_[2].pop_connected[1], mesh_DUT._rw_[1]._clm_[2].pop_connected[2], mesh_DUT._rw_[1]._clm_[2].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[1]._clm_[2].pop_connected[0]) begin
                    paths.row = 1;
                    paths.colum = 2;
                    paths.paquete = mesh_DUT._rw_[1]._clm_[2].data_out_connected[0];
                    paths.print("[AMBIENTE]");
                    path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[2].pop_connected[1]) begin
                    paths.row = 1;
                    paths.colum = 2;
                    paths.paquete = mesh_DUT._rw_[1]._clm_[2].data_out_connected[1];
                    paths.print("[AMBIENTE]");
                    path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[2].pop_connected[2]) begin
                    paths.row = 1;
                    paths.colum = 2;
                    paths.paquete = mesh_DUT._rw_[1]._clm_[2].data_out_connected[2];
                    paths.print("[AMBIENTE]");
                    path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[2].pop_connected[3]) begin
                    paths.row = 1;
                    paths.colum = 2;
                    paths.paquete = mesh_DUT._rw_[1]._clm_[2].data_out_connected[3];
                    paths.print("[AMBIENTE]");
                    path_chkr_mbx.put(paths);
				end
			end

			//ID 13
			if ({mesh_DUT._rw_[1]._clm_[3].pop_connected[0], mesh_DUT._rw_[1]._clm_[3].pop_connected[1], mesh_DUT._rw_[1]._clm_[3].pop_connected[2], mesh_DUT._rw_[1]._clm_[3].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[1]._clm_[3].pop_connected[0]) begin
					paths.row = 1;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[1]._clm_[3].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[3].pop_connected[1]) begin
					paths.row = 1;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[1]._clm_[3].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[3].pop_connected[2]) begin
					paths.row = 1;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[1]._clm_[3].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[3].pop_connected[3]) begin
					paths.row = 1;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[1]._clm_[3].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 14
			if ({mesh_DUT._rw_[1]._clm_[4].pop_connected[0], mesh_DUT._rw_[1]._clm_[4].pop_connected[1], mesh_DUT._rw_[1]._clm_[4].pop_connected[2], mesh_DUT._rw_[1]._clm_[4].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[1]._clm_[4].pop_connected[0]) begin
					paths.row = 1;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[1]._clm_[4].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[4].pop_connected[1]) begin
					paths.row = 1;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[1]._clm_[4].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[4].pop_connected[2]) begin
					paths.row = 1;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[1]._clm_[4].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[1]._clm_[4].pop_connected[3]) begin
					paths.row = 1;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[1]._clm_[4].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 21
			if ({mesh_DUT._rw_[2]._clm_[1].pop_connected[0], mesh_DUT._rw_[2]._clm_[1].pop_connected[1], mesh_DUT._rw_[2]._clm_[1].pop_connected[2], mesh_DUT._rw_[2]._clm_[1].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[2]._clm_[1].pop_connected[0]) begin
					paths.row = 2;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[2]._clm_[1].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[1].pop_connected[1]) begin
					paths.row = 2;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[2]._clm_[1].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[1].pop_connected[2]) begin
					paths.row = 2;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[2]._clm_[1].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[1].pop_connected[3]) begin
					paths.row = 2;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[2]._clm_[1].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end	

			//ID 22
			if ({mesh_DUT._rw_[2]._clm_[2].pop_connected[0], mesh_DUT._rw_[2]._clm_[2].pop_connected[1], mesh_DUT._rw_[2]._clm_[2].pop_connected[2], mesh_DUT._rw_[2]._clm_[2].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[2]._clm_[2].pop_connected[0]) begin
					paths.row = 2;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[2]._clm_[2].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[2].pop_connected[1]) begin
					paths.row = 2;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[2]._clm_[2].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[2].pop_connected[2]) begin
					paths.row = 2;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[2]._clm_[2].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[2].pop_connected[3]) begin
					paths.row = 2;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[2]._clm_[2].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 23
			if ({mesh_DUT._rw_[2]._clm_[3].pop_connected[0], mesh_DUT._rw_[2]._clm_[3].pop_connected[1], mesh_DUT._rw_[2]._clm_[3].pop_connected[2], mesh_DUT._rw_[2]._clm_[3].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[2]._clm_[3].pop_connected[0]) begin
					paths.row = 2;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[2]._clm_[3].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[3].pop_connected[1]) begin
					paths.row = 2;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[2]._clm_[3].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[3].pop_connected[2]) begin
					paths.row = 2;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[2]._clm_[3].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[3].pop_connected[3]) begin
					paths.row = 2;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[2]._clm_[3].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 24
			if ({mesh_DUT._rw_[2]._clm_[4].pop_connected[0], mesh_DUT._rw_[2]._clm_[4].pop_connected[1], mesh_DUT._rw_[2]._clm_[4].pop_connected[2], mesh_DUT._rw_[2]._clm_[4].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[2]._clm_[4].pop_connected[0]) begin
					paths.row = 2;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[2]._clm_[4].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[4].pop_connected[1]) begin
					paths.row = 2;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[2]._clm_[4].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[4].pop_connected[2]) begin
					paths.row = 2;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[2]._clm_[4].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[2]._clm_[4].pop_connected[3]) begin
					paths.row = 2;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[2]._clm_[4].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 31
			if ({mesh_DUT._rw_[3]._clm_[1].pop_connected[0], mesh_DUT._rw_[3]._clm_[1].pop_connected[1], mesh_DUT._rw_[3]._clm_[1].pop_connected[2], mesh_DUT._rw_[3]._clm_[1].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[3]._clm_[1].pop_connected[0]) begin
					paths.row = 3;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[3]._clm_[1].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[1].pop_connected[1]) begin
					paths.row = 3;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[3]._clm_[1].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[1].pop_connected[2]) begin
					paths.row = 3;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[3]._clm_[1].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[1].pop_connected[3]) begin
					paths.row = 3;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[3]._clm_[1].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 32
			if ({mesh_DUT._rw_[3]._clm_[2].pop_connected[0], mesh_DUT._rw_[3]._clm_[2].pop_connected[1], mesh_DUT._rw_[3]._clm_[2].pop_connected[2], mesh_DUT._rw_[3]._clm_[2].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[3]._clm_[2].pop_connected[0]) begin
					paths.row = 3;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[3]._clm_[2].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[2].pop_connected[1]) begin
					paths.row = 3;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[3]._clm_[2].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[2].pop_connected[2]) begin
					paths.row = 3;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[3]._clm_[2].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[2].pop_connected[3]) begin
					paths.row = 3;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[3]._clm_[2].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 33
			if ({mesh_DUT._rw_[3]._clm_[3].pop_connected[0], mesh_DUT._rw_[3]._clm_[3].pop_connected[1], mesh_DUT._rw_[3]._clm_[3].pop_connected[2], mesh_DUT._rw_[3]._clm_[3].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[3]._clm_[3].pop_connected[0]) begin
					paths.row = 3;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[3]._clm_[3].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[3].pop_connected[1]) begin
					paths.row = 3;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[3]._clm_[3].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[3].pop_connected[2]) begin
					paths.row = 3;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[3]._clm_[3].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[3].pop_connected[3]) begin
					paths.row = 3;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[3]._clm_[3].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 34
			if ({mesh_DUT._rw_[3]._clm_[4].pop_connected[0], mesh_DUT._rw_[3]._clm_[4].pop_connected[1], mesh_DUT._rw_[3]._clm_[4].pop_connected[2], mesh_DUT._rw_[3]._clm_[4].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[3]._clm_[4].pop_connected[0]) begin
					paths.row = 3;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[3]._clm_[4].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[4].pop_connected[1]) begin
					paths.row = 3;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[3]._clm_[4].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[4].pop_connected[2]) begin
					paths.row = 3;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[3]._clm_[4].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[3]._clm_[4].pop_connected[3]) begin
					paths.row = 3;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[3]._clm_[4].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 41
			if ({mesh_DUT._rw_[4]._clm_[1].pop_connected[0], mesh_DUT._rw_[4]._clm_[1].pop_connected[1], mesh_DUT._rw_[4]._clm_[1].pop_connected[2], mesh_DUT._rw_[4]._clm_[1].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[4]._clm_[1].pop_connected[0]) begin
					paths.row = 4;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[4]._clm_[1].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[1].pop_connected[1]) begin
					paths.row = 4;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[4]._clm_[1].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[1].pop_connected[2]) begin
					paths.row = 4;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[4]._clm_[1].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[1].pop_connected[3]) begin
					paths.row = 4;
					paths.colum = 1;
					paths.paquete = mesh_DUT._rw_[4]._clm_[1].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 42
			if ({mesh_DUT._rw_[4]._clm_[2].pop_connected[0], mesh_DUT._rw_[4]._clm_[2].pop_connected[1], mesh_DUT._rw_[4]._clm_[2].pop_connected[2], mesh_DUT._rw_[4]._clm_[2].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[4]._clm_[2].pop_connected[0]) begin
					paths.row = 4;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[4]._clm_[2].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[2].pop_connected[1]) begin
					paths.row = 4;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[4]._clm_[2].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[2].pop_connected[2]) begin
					paths.row = 4;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[4]._clm_[2].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[2].pop_connected[3]) begin
					paths.row = 4;
					paths.colum = 2;
					paths.paquete = mesh_DUT._rw_[4]._clm_[2].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 43
			if ({mesh_DUT._rw_[4]._clm_[3].pop_connected[0], mesh_DUT._rw_[4]._clm_[3].pop_connected[1], mesh_DUT._rw_[4]._clm_[3].pop_connected[2], mesh_DUT._rw_[4]._clm_[3].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[4]._clm_[3].pop_connected[0]) begin
					paths.row = 4;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[4]._clm_[3].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[3].pop_connected[1]) begin
					paths.row = 4;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[4]._clm_[3].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[3].pop_connected[2]) begin
					paths.row = 4;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[4]._clm_[3].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[3].pop_connected[3]) begin
					paths.row = 4;
					paths.colum = 3;
					paths.paquete = mesh_DUT._rw_[4]._clm_[3].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end

			//ID 44
			if ({mesh_DUT._rw_[4]._clm_[4].pop_connected[0], mesh_DUT._rw_[4]._clm_[4].pop_connected[1], mesh_DUT._rw_[4]._clm_[4].pop_connected[2], mesh_DUT._rw_[4]._clm_[4].pop_connected[3]} != 4'b0000) begin
				if (mesh_DUT._rw_[4]._clm_[4].pop_connected[0]) begin
					paths.row = 4;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[4]._clm_[4].data_out_connected[0];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[4].pop_connected[1]) begin
					paths.row = 4;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[4]._clm_[4].data_out_connected[1];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[4].pop_connected[2]) begin
					paths.row = 4;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[4]._clm_[4].data_out_connected[2];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end

				if (mesh_DUT._rw_[4]._clm_[4].pop_connected[3]) begin
					paths.row = 4;
					paths.colum = 4;
					paths.paquete = mesh_DUT._rw_[4]._clm_[4].data_out_connected[3];
					paths.print("[AMBIENTE]");
					path_chkr_mbx.put(paths);
				end
			end
		end
	endtask

endmodule
