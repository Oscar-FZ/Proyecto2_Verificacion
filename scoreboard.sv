//Clase que define el funcionamiento del ScoreBoard
class scoreboard #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});
	//Se crean los paquetes necesarios para el scoreboard
	sb_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) trans_sb;
	sb_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) trans_sb_aux[$];
	sb_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) auxiliar;

	//Se crea el mailbox que recibe los paquetes del checker
	sb_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) chkr_sb_mbx;

	//Se crean las variables necesarias para el funcionamiento correcto del scoreboard
	int num_trans;
	int num_trans_aux;
	int inicio_a;
	int inicio_min;
	int inicio_max;
	int j;
	int rprt_al;
	int rprt_min;
	int rprt_max;
	int proms_al;
	int proms_min;
	int proms_max;
	int ret_prom;
	int num_tot;
	int tiempo_inicio;
	int tiempo_final;


	int ret_x_terminal [16];
	int num_trans_x_terminal [16];
	
	function new();
		chkr_sb_mbx = new();
		inicio_a = 1;
		inicio_min = 1;
		inicio_max = 1;
		num_trans_aux = 0;
		tiempo_inicio = 0;
		tiempo_final = 0;
	endfunction

	task run();
		num_trans_aux = 0;
		$display("[SCOREBOARD][%g] El Score Board inicio", $time);
		forever begin
			#1;
			if (chkr_sb_mbx.num()>0) begin
				$display("[SCOREBOARD] Transaccion recibida");
				chkr_sb_mbx.get(trans_sb);
				ret_x_terminal[trans_sb.dir_rec] += trans_sb.latencia;
				num_trans_x_terminal[trans_sb.dir_rec] += 1;
				$display("[RETARDO] %p", ret_x_terminal);
				$display("[NUMTRANSxTERMINAL] %p", num_trans_x_terminal);
				num_trans_aux++;

				$display("[SCOREBOARD] Imprimiendo Archivos");
				case(trans_sb.tipo)
				aleatorio: begin
					if (inicio_a) begin //Si es el inicio del reporte escribe esto primero
						tiempo_inicio = trans_sb.tiempo_env;
						rprt_al = $fopen("reporte_scoreboard.csv", "w");
						$fwrite(rprt_al, "Rows; %d\n", ROWS);
						$fwrite(rprt_al, "Columns; %d\n", COLUMS);
						$fwrite(rprt_al, "Package Size; %d\n", pckg_sz);
						$fwrite(rprt_al, "FIFO depth; %d\n", fifo_depth);
						$fwrite(rprt_al, "Broadcast ID; %b\n", bdcst);
						$fwrite(rprt_al, ";Paquete; Estado; Direccion de Envio; Direccion de Recepcion; Tiempo de Envio; Tiempo de Recepcion; Latencia\n");
						$fclose(rprt_al);
						inicio_a = 0;
					end
					tiempo_final = trans_sb.tiempo_rec;
					//Escribe la informacion de los pauetes enviados por el checker
					rprt_al = $fopen("reporte_scoreboard.csv", "a");
					$fwrite(rprt_al, "%d; 0x%h; %b; 0x%h; 0x%h; %g; %g; %g\n", num_trans_aux, trans_sb.paquete, trans_sb.completado, trans_sb.dir_env, trans_sb.dir_rec, trans_sb.tiempo_env, trans_sb.tiempo_rec, trans_sb.latencia);
					$fclose(rprt_al);
					
					ret_prom = 0;
					num_tot = 0;
					proms_al = $fopen("promedio_scoreboard.csv", "w");
					$fwrite(proms_al, "Rows; %d\n", ROWS);
					$fwrite(proms_al, "Columns; %d\n", COLUMS);
					$fwrite(proms_al, "Package Size; %d\n", pckg_sz);
					$fwrite(proms_al, "FIFO depth; %d\n", fifo_depth);
					$fwrite(proms_al, "Broadcast ID; %b\n", bdcst);
					$fwrite(proms_al, "Terminal; Retardo Promedio\n");
					for (int i = 0; i < 16; i++) begin
						ret_prom += ret_x_terminal[i]; 
						num_tot += num_trans_x_terminal[i];
						if (num_trans_x_terminal[i] > 0) begin
							$fwrite(proms_al, "%d; %d\n", i, (ret_x_terminal[i]/num_trans_x_terminal[i]));
						end
						
						else $fwrite(proms_al, "%d; %d\n", i, 0);

						
					end
					$fwrite(proms_al, "Promedio General; %d\n", (ret_prom/num_tot));
					$fwrite(proms_al, "Ancho de Banda; %d\n", (num_tot*pckg_sz*1000)/(tiempo_final-tiempo_inicio));
					$fclose(proms_al);

				end

				ret_min: begin
					if (inicio_min) begin //Si es el inicio del reporte escribe esto primero
						rprt_min = $fopen("reporte_scoreboard_min.csv", "w");
						$fwrite(rprt_min, "Rows; %d\n", ROWS);
						$fwrite(rprt_min, "Columns; %d\n", COLUMS);
						$fwrite(rprt_min, "Package Size; %d\n", pckg_sz);
						$fwrite(rprt_min, "FIFO depth; %d\n", fifo_depth);
						$fwrite(rprt_min, "Broadcast ID; %b\n", bdcst);
						$fwrite(rprt_min, ";Paquete; Estado; Direccion de Envio; Direccion de Recepcion; Tiempo de Envio; Tiempo de Recepcion; Latencia\n");
						$fclose(rprt_min);
						inicio_min = 0;
					end
					//Escribe la informacion de los pauetes enviados por el checker
					rprt_min = $fopen("reporte_scoreboard_min.csv", "a");
					$fwrite(rprt_min, "%d; 0x%h; %b; 0x%h; 0x%h; %g; %g; %g\n", num_trans_aux, trans_sb.paquete, trans_sb.completado, trans_sb.dir_env, trans_sb.dir_rec, trans_sb.tiempo_env, trans_sb.tiempo_rec, trans_sb.latencia);
					$fclose(rprt_min);
				end

				ret_max: begin
					if (inicio_max) begin //Si es el inicio del reporte escribe esto primero
						rprt_max = $fopen("reporte_scoreboard_max.csv", "w");
						$fwrite(rprt_max, "Rows; %d\n", ROWS);
						$fwrite(rprt_max, "Columns; %d\n", COLUMS);
						$fwrite(rprt_max, "Package Size; %d\n", pckg_sz);
						$fwrite(rprt_max, "FIFO depth; %d\n", fifo_depth);
						$fwrite(rprt_max, "Broadcast ID; %b\n", bdcst);
						$fwrite(rprt_max, ";Paquete; Estado; Direccion de Envio; Direccion de Recepcion; Tiempo de Envio; Tiempo de Recepcion; Latencia\n");
						$fclose(rprt_max);
						inicio_max = 0;
					end
					//Escribe la informacion de los pauetes enviados por el checker
					rprt_max = $fopen("reporte_scoreboard_max.csv", "a");
					$fwrite(rprt_max, "%d; 0x%h; %b; 0x%h; 0x%h; %g; %g; %g\n", num_trans_aux, trans_sb.paquete, trans_sb.completado, trans_sb.dir_env, trans_sb.dir_rec, trans_sb.tiempo_env, trans_sb.tiempo_rec, trans_sb.latencia);
					$fclose(rprt_max);
				end

				endcase	
			end

			//if (num_trans_aux == num_trans) break;
		end
	endtask

endclass

