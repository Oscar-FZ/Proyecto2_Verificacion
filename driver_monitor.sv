class fifo #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});
	
	bit [pckg_sz-1:0] queue_in [$];
	bit pndng_in;
	bit [pckg_sz-1:0] data_in;

	bit [pckg_sz-1:0] queue_out [$];
	bit pndng_out;
	bit [pckg_sz-1:0] data_out;

	bit id;

	virtual mesh_if #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) vif;


	function new (input int identificador);
		this.queue_in = {};
		this.pndng_in = 0;
		this.data_in = 0;
		this.queue_out = {};
		this.pndng_out = 0;
		this.data_out = 0;
		this.id = identificador;
	endfunction


	task update_vif_pndng();
		forever begin
			@(negedge vif.clk);
			vif.pndng_i_in[id] = pndng_in;
		end
	endtask

	task send_data_mesh();
		forever begin
			@(posedge vif.clk)
			vif.data_out_i_in[id] = queue_in[$];
			if (vif.popin[id]) begin
				queue_in.pop_back();
			end

			if (queue_in.size() != 0) 
                pndng_in = 1;
            else
                pndng_in = 0;
		end
	endtask


	task receive_data_mesh();
		forever begin
			@(posedge vif.clk);
			if (vif.pndng[id]) begin
				queue_out.push_front(vif.data_out[id]);
				vif.pop[id] = 1'b1;
			end

			else vif.pop[id] = 1'b0;

			if (queue_out.size() != 0) pndng_out = 1;

            else pndng_out = 0;
		end
	endtask
endclass

class drvr_mntr #(parameter ROWS = 4, parameter COLUMS =4, parameter pckg_sz =40, parameter fifo_depth = 4, parameter bdcst= {8{1'b1}});

	
	fifo #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) fifo_hijo;


	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) transaccion;
	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) transaccion_mntr;

	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_drvr_mbx[ROWS*2+COLUMS*2];


	int espera;
	int id;

	function new (input int identificador);
		fifo_hijo = new(identificador);
		id = identificador;
		transaccion = new();
		transaccion_mntr = new();

		for (int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			agnt_drvr_mbx[i] = new();
		end


	endfunction

	task run_drvr();
		$display("[ID] %d", id);
        $display("[%g] El Driver fue inicializado", $time);

		fork
			fifo_hijo.update_vif_pndng();
			fifo_hijo.send_data_mesh();
		join_none
		@(posedge fifo_hijo.vif.clk);
		forever begin
			fifo_hijo.vif.reset = 0;
			espera = 0;

			agnt_drvr_mbx[id].get(transaccion);
			while (espera < transaccion.retardo) begin
				@(posedge fifo_hijo.vif.clk);
				espera = espera + 1;
			end
			
			$display("[ESCRITURA]");
			transaccion.tiempo = $time;
			fifo_hijo.queue_in.push_front(transaccion.paquete);
			transaccion.print("[DRIVER] DATO ENVIADO");

		end
	endtask


endclass

class strt_drvr_mntr #(parameter ROWS = 4, parameter COLUMS =4, parameter pckg_sz =40, parameter fifo_depth = 4, parameter bdcst= {8{1'b1}});
	drvr_mntr #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) drvr_mntr_hijo [ROWS*2+COLUMS*2];

	function new();
		for(int i = 0; i < (ROWS*2+COLUMS*2); i++) begin
			drvr_mntr_hijo[i] = new(i);
		end
	endfunction


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

endclass


