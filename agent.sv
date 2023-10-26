class agent #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});
	

	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_drvr_mbx[ROWS*2+COLUMS*2];

	instr_pckg_mbx test_agnt_mbx;

	instrucciones tipo;
	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) transaccion;

	int num_trans;
	int max_retardo_agnt;
	int retardo_agnt;

	function new();
		for (int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			agnt_drvr_mbx[i] = new();
		end
		test_agnt_mbx = new();
	endfunction


	task run();
		$display("[%g] El Agente fue iniciado", $time);
		forever begin
			#1;
			if (test_agnt_mbx.num()>0) begin
				test_agnt_mbx.get(tipo);
				case(tipo)
					aleatorio: begin
						for (int i = 0; i<num_trans; i++) begin
							$display("[AGENT] %d", i);
							transaccion = new(.max_retardo_n(max_retardo_agnt));
							transaccion.randomize();
							transaccion.crea_paquetes();
							agnt_drvr_mbx[transaccion.dir_env].put(transaccion);
							transaccion.print("[AGENT] PAQUETE CREADO");
						end
					end
				endcase
			end
		end
	endtask


endclass
