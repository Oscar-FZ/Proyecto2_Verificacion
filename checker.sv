class checker_p #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});
	
	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) transaccion;
	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) transaccion_aux;

	sb_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) to_sb;
	path_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) trans_path;
	
	mesh_pckg #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) emul_fifo[$];
	
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) agnt_chkr_mbx;
	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) mntr_chkr_mbx;
	path_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) path_chkr_mbx;

	mesh_pckg_mbx #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth), .bdcst(bdcst)) chkr_sb_mbx;
	
	int cont_aux;
	int cont;

	int dict [bit [pckg_sz-9:0]][$];


	function new();
		emul_fifo = {};
		cont_aux = 0;
		cont = 0;
		to_sb = new();
		transaccion = new();
		transaccion_aux = new();
		trans_path = new();

		agnt_chkr_mbx = new();
		mntr_chkr_mbx = new();
		chkr_sb_mbx = new();
		path_chkr_mbx = new();
	endfunction

	task update();
		$display("[%g] El Checker se esta actualizando", $time);
		forever begin
			agnt_chkr_mbx.get(transaccion_aux);
			emul_fifo.push_front(transaccion_aux);
		end	
	endtask

	task update_path();
		forever begin
			path_chkr_mbx.get(trans_path);
			dict[trans_path.paquete[pckg_sz-9:0]].push_back(trans_path.row);
			dict[trans_path.paquete[pckg_sz-9:0]].push_back(trans_path.colum);
			$display("[DICCIONARIO][%d] Key: %h - array: %p", dict.num(), trans_path.paquete[pckg_sz-9:0], dict[trans_path.paquete[pckg_sz-9:0]]);

		end
	endtask

	task check();
		$display("[%g] El Checker esta revisando", $time);
		cont = 0;
		forever begin
			mntr_chkr_mbx.get(transaccion);
			cont_aux = 1;
			for (int i = 0; i < emul_fifo.size(); i++) begin
				//$display("[CHECKER] %d", i);
				if (emul_fifo[i].paquete[pckg_sz-9:0] == transaccion.paquete[pckg_sz-9:0]) begin
					cont_aux = 0;
					to_sb.paquete = transaccion.paquete;
					to_sb.dir_env = emul_fifo[i].dir_env;
					to_sb.dir_rec = transaccion.dir_rec;
					to_sb.completado = 1;
					to_sb.tiempo_env = emul_fifo[i].tiempo;
					to_sb.tiempo_rec = transaccion.tiempo;
					to_sb.calc_latencia();
					to_sb.print("[CHECKER]");
					chkr_sb_mbx.put(to_sb);	
				end
			end
			if (cont_aux) cont = cont + 1;
			$display("[CHECKER] cont = %d", cont);
		end
	endtask

	
	

endclass
