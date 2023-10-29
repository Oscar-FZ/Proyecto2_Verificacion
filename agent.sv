//Clase que define el funcionamiento del Agente
class agent #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});
	
	//Se crean los mailboxes que se van a conectar a todos los drivers
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_drvr_mbx[ROWS*2+COLUMS*2];
	//mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_chkr_mbx;

	//Se crea el mailbox que va a recivir las pruebas del test
	instr_pckg_mbx test_agnt_mbx;

	//Tipo de variable que se va a recibir por el mailbox del Test
	instrucciones tipo;
	//Tipo de paquete que se va a crear y envia rla driver
	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) transaccion;
	
	int num_trans; 			//Numero de paquetes que se vana  crear 
	int max_retardo_agnt; 	//Retardo maximo de los paquetes
	//int retardo_agnt;
	
	//Inicializo todos los mailboxes
	function new();
		for (int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			agnt_drvr_mbx[i] = new();
		end
		//agnt_chkr_mbx = new();
		test_agnt_mbx = new();
	endfunction


	//Task que inicia el funcionamiento del Agente
	task run();
		$display("[%g] El Agente fue iniciado", $time);
		forever begin
			#1;
			//Se esperan pruebas del Test
			if (test_agnt_mbx.num()>0) begin
				test_agnt_mbx.get(tipo);
				//Se crean los paquetes dependiendo de la prueba que se recibio
				case(tipo)
					aleatorio: begin //Crea paquetes con contenido aleatorio y se envian al driver
						for (int i = 0; i<num_trans; i++) begin
							//$display("[AGENT] %d", i);
							transaccion = new(.max_retardo_n(max_retardo_agnt));
							transaccion.randomize();
							transaccion.crea_paquetes();
							//transaccion.tiempo = $time;
							agnt_drvr_mbx[transaccion.dir_env].put(transaccion);
							//agnt_chkr_mbx.put(transaccion);
							//transaccion.print("[AGENT] PAQUETE CREADO");
						end
					end
				endcase
			end
		end
	endtask


endclass
