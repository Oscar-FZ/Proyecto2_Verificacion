//Clase que simula la fifo de los datos de entrada y salida del DUT
class fifo #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});
	
	bit [pckg_sz-1:0] queue_in [$];
	bit pndng_in;
	bit [pckg_sz-1:0] data_in;

	bit [pckg_sz-1:0] queue_out [$];
	bit pndng_out;
	bit [pckg_sz-1:0] data_out;

	int id;

	//Interfaz virrtual del DUT
	virtual mesh_if #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) vif;

	//Funcion que crea los fifo
	function new (input int identificador);
		this.queue_in = {};
		this.pndng_in = 0;
		this.data_in = 0;
		this.queue_out = {};
		this.pndng_out = 0;
		this.data_out = 0;
		this.id = identificador;
	endfunction

	//Task que actualiza el pndng_i_in del DUT
	task update_vif_pndng();
		forever begin
			@(negedge vif.clk);
			vif.pndng_i_in[id] = pndng_in;
		end
	endtask

	//Task que envia los datos al DUT
	task send_data_mesh();
		forever begin
			@(posedge vif.clk)
			vif.data_out_i_in[id] = queue_in[$];
			//$display("[DRIVER][%d] queue_in[$]: 0x%h", id, queue_in[$]);
			if (vif.popin[id]) begin
				//$display("WOOOOOOOOOOOOOOOOOOO");
				//$display("[QUEUE] %p [ID] %d", queue_in, id);
				queue_in.pop_back();
			end

			if (queue_in.size() != 0) 
                pndng_in = 1;
            else
                pndng_in = 0;
		end
	endtask


	//Task que recive los datos del DUT
	task receive_data_mesh();
		forever begin
			@(posedge vif.clk);
			if (vif.pndng[id] && !vif.pop[id]) begin
				queue_out.push_front(vif.data_out[id]);
				vif.pop[id] = 1'b1;
			end

			else vif.pop[id] = 1'b0;

			if (queue_out.size() != 0) pndng_out = 1;

            else pndng_out = 0;
		end
	endtask
endclass

//Clase que describe el funcionamiento del Driver y Monitor
class drvr_mntr #(parameter ROWS = 4, parameter COLUMS =4, parameter pckg_sz =40, parameter fifo_depth = 4, parameter bdcst= {8{1'b1}});

	//Instanciamos un fifo
	fifo #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) fifo_hijo;

	//Creamos los paquetes que se van a usar en los mailboxes
	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) transaccion;
	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) transaccion_mntr;

	//Instanciamos los mailboxes
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_drvr_mbx[ROWS*2+COLUMS*2];
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) mntr_chkr_mbx;
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) drvr_chkr_mbx;

	int espera; 	//Variable usada en el conteo del retraso de cada paquete 
	int id; 		//Varible que identifica cada driver y monitor

	//Iniciamos los paquetes, mailboxes y variables
	function new (input int identificador);
		fifo_hijo = new(identificador);
		id = identificador;
		transaccion = new();
		transaccion_mntr = new();

		for (int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			agnt_drvr_mbx[i] = new();
		end

		mntr_chkr_mbx = new();
		drvr_chkr_mbx = new();


	endfunction

	//Task que inicia el funcionamiento del driver
	task run_drvr();
		agnt_drvr_mbx[id].peek(transaccion);
		$display("[ID] %d", id);
        $display("[%g] El Driver fue inicializado", $time);
		//Iniciamos las tareas relacionadas con el driver
		fork
			fifo_hijo.update_vif_pndng();
			fifo_hijo.send_data_mesh();
		join_none
		@(posedge fifo_hijo.vif.clk);
		forever begin
			//Introduciomos los paquetes del driver al DUT
			fifo_hijo.vif.reset = 0;
			espera = 0;

			agnt_drvr_mbx[id].get(transaccion);
			transaccion.tiempo = $time;
			while (espera < transaccion.retardo) begin
				@(posedge fifo_hijo.vif.clk);
				espera = espera + 1;
			end
			
			//$display("[%g][ESCRITURA][%d]", $time, id);

			fifo_hijo.queue_in.push_front(transaccion.paquete);
			drvr_chkr_mbx.put(transaccion);
			transaccion.print("[DRIVER] DATO ENVIADO");

		end
		$display("[ERROR!!!!]");
	endtask

	//Task que inicia el funcionamiento del monitor
	task run_mntr();
		$display("[ID] %d", id);
        $display("[%g] El Monitor fue inicializado", $time);
		//Ejecutamos las tareas correspodientes al monitr
		fork
			fifo_hijo.receive_data_mesh();
		join_none

		forever begin
			//Sacamos los paquetes del DUT y los mandamos al checker
			@(posedge fifo_hijo.vif.clk);
			if (fifo_hijo.pndng_out) begin
				//$display("[%g][LECTURA][%d]", $time, id);
				//$display("[MONITOR][%d] queue_out[$]: %p", id, fifo_hijo.queue_out);

				transaccion_mntr.tiempo = $time;
				transaccion_mntr.dir_rec = id;
				transaccion_mntr.paquete = fifo_hijo.queue_out.pop_back();
				transaccion_mntr.print("[MONITOR] DATO RECIVIDO");
				mntr_chkr_mbx.put(transaccion_mntr);
			end
		end
	endtask


endclass

//Clase que inicializa todos los driver y monitores
class strt_drvr_mntr #(parameter ROWS = 4, parameter COLUMS =4, parameter pckg_sz =40, parameter fifo_depth = 4, parameter bdcst= {8{1'b1}});
	drvr_mntr #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) drvr_mntr_hijo [ROWS*2+COLUMS*2];
	//Instanciamos todos los driver y monitores necesarios
	function new();
		for(int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			drvr_mntr_hijo[i] = new(i);
		end
	endfunction

	//Ejecutamos todos los Drivers
	task start_driver();
		for(int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			fork
				automatic int j=i;
				begin
					drvr_mntr_hijo[j].run_drvr();
				end
			join_none
		end
	endtask

	//Ejecutamos todos lo monitores
	task start_monitor();
		for(int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			fork
				automatic int j=i;
				begin
					drvr_mntr_hijo[j].run_mntr();
				end
			join_none
		end
	endtask

endclass


