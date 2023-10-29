class scoreboard #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});
	
	sb_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) trans_sb;
	sb_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) trans_sb_aux[$];
	sb_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) auxiliar;

	sb_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) chkr_sb_mbx;
	
	int num_trans;
	int num_trans_aux;
	int inicio;
	int j;
	int rprt_sb;
	
	function new();
		chkr_sb_mbx = new();
		inicio = 1;
		num_trans_aux = 0;
	endfunction

	task run();
		num_trans_aux = 0;
		$display("[SCOREBOARD][%g] El Score Board inicio", $time);
		forever begin
			#1;
			if (chkr_sb_mbx.num()>0) begin
				$display("[SCOREBOARD] Transaccion recibida");
				chkr_sb_mbx.get(trans_sb);
				num_trans_aux++;

				$display("[SCOREBOARD] Imprimiendo Archivos");
				if (inicio) begin
					rprt_sb = $fopen("reporte_scoreboard.csv", "w");
					$fwrite(rprt_sb, ";Paquete; Estado; Direccion de Envio; Direccion de Recepcion; Tiempo de Envio; Tiempo de Recepcion; Latencia\n");
					$fclose(rprt_sb);
					inicio = 0;
				end
				rprt_sb = $fopen("reporte_scoreboard.csv", "a");


				$fwrite(rprt_sb, "[%d]; 0x%h; %b; 0x%h; 0x%h; %g; %g; %g\n", num_trans_aux, trans_sb.paquete, trans_sb.completado, trans_sb.dir_env, trans_sb.dir_rec, trans_sb.tiempo_env, trans_sb.tiempo_rec, trans_sb.latencia);
				$fclose(rprt_sb);	
			end

			if (num_trans_aux == num_trans) break;
		end
	endtask

endclass

