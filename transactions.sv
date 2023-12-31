//Tipo de operaciones que puede realizar el agente
typedef enum 
	{
	aleatorio,
	ret_min,
	ret_max,
	broadcast,
	overload
	} instrucciones;
    
//Clase que define el tipo de paquetes que pueden ser enviados y recibidos por el DUT
class mesh_pckg #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});

	bit [7:0] nxt_jump;
	bit [3:0] t_row;
	bit [3:0] t_col;
	rand bit [11:0] t_row_col;
	rand bit mode;
	rand bit [pckg_sz-18:0] pyld;
	bit [pckg_sz-1:0] paquete;
	instrucciones tipo;

	rand int retardo;
	int tiempo;
	int max_retardo;
	rand bit [3:0]dir_env;
	bit [3:0]dir_rec;

	constraint const_retardo {retardo <= max_retardo; retardo > 0;}
	constraint const_t_row_col {t_row_col inside{12'h01_0, 12'h02_1, 12'h03_2, 12'h04_3, 12'h10_4, 12'h20_5, 12'h30_6, 12'h40_7, 12'h51_8, 12'h52_9, 12'h53_A, 12'h54_B, 12'h15_C, 12'h25_D, 12'h35_E, 12'h45_F};}
	constraint const_dir_env {dir_env >= 0; dir_env <= 15;}
	constraint const_dir_env_dif {dir_env != t_row_col[3:0];}

	function new(bit [7:0] nxt_jump_n = 8'b0, bit [3:0] t_row_n = 4'b0, bit [3:0] t_col_n = 4'b0, bit mode_n = 1'b0, bit [pckg_sz-18:0] pyld_n = 0, int retardo_n = 5, int tiempo_n = 0, int max_retardo_n = 10, bit [3:0] dir_env_n = 0, bit [3:0] dir_rec_n = 0);
		this.nxt_jump 		= nxt_jump_n;
		this.t_row 			= t_row_n;
		this.t_col 			= t_col_n;
		this.mode 			= mode_n;
		this.pyld 			= pyld_n;
		this.paquete 		= 0;
		this.retardo 		= retardo_n;
		this.tiempo 		= tiempo_n;
		this.max_retardo 	= max_retardo_n;
		this.dir_env 		= dir_env_n;
		this.dir_rec 		= dir_rec_n;
		this.tipo 		= aleatorio;
	endfunction

	task crea_paquetes();
		this.paquete = {this.nxt_jump, this.t_row_col[11:4], this.mode, this.pyld};
	endtask

	task crea_dir_rec();
		case(this.dir_rec)
			4'h0: this.t_row_col = 12'h01_0;
			4'h1: this.t_row_col = 12'h02_1;
			4'h2: this.t_row_col = 12'h03_2;
			4'h3: this.t_row_col = 12'h04_3;
			4'h4: this.t_row_col = 12'h10_4;
			4'h5: this.t_row_col = 12'h20_5;
			4'h6: this.t_row_col = 12'h30_6;
			4'h7: this.t_row_col = 12'h40_7;
			4'h8: this.t_row_col = 12'h51_8;
			4'h9: this.t_row_col = 12'h52_9;
			4'hA: this.t_row_col = 12'h53_A;
			4'hB: this.t_row_col = 12'h54_B;
			4'hC: this.t_row_col = 12'h15_C;
			4'hD: this.t_row_col = 12'h25_D;
			4'hE: this.t_row_col = 12'h35_E;
			4'hF: this.t_row_col = 12'h45_F;	
		endcase
	endtask

	function void print(input string tag = "");
		$display("---------------------------");
		$display("[TIME %g]", $time);
        $display("%s", tag);
		$display("Dir Env = 0x%h", this.dir_env);
		$display("Dir Rec = 0x%h", this.dir_rec);
		$display("Paquete = 0x%h",this.paquete);
		$display("---------------------------");
	endfunction
endclass

//Clase que define los paquetes para comunicarse con el scoreboard
class sb_pckg #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});
	
	bit [pckg_sz-1:0] paquete;
	bit [3:0] dir_env;
	bit [3:0] dir_rec;
	bit completado;
	int tiempo_env;
	int tiempo_rec;
	int latencia;
	instrucciones tipo;


	function new();
		this.paquete = 0;
		this.dir_env = 0;
		this.dir_rec = 0;
		this.completado = 0;
		this.tiempo_env = 0;
		this.tiempo_rec = 0;
		this.latencia = 0;
		this.tipo = aleatorio;
	endfunction

	task calc_latencia();
		this.latencia = this.tiempo_rec - this.tiempo_env;
	endtask

	function void print(input string tag = "");
		$display("---------------------------");
		$display("[TIME %g]", $time);
        $display("%s", tag);
		$display("Dir Env = 0x%h", this.dir_env);
		$display("Tiempo Env = %g", this.tiempo_env);
		$display("Dir Rec = 0x%h", this.dir_rec);
		$display("Tiempo Rec = %g", this.tiempo_rec);
		$display("Paquete = 0x%h",this.paquete);
		$display("Latencia = %g", this.latencia);
		$display("---------------------------");
	endfunction

endclass

//Clase que define los paquetes que guardan la informacion del path de los paquetes que viajan por el DUT
class path_pckg #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});	
	int row;
	int colum;
	bit [pckg_sz-1:0] paquete;

	function new();
		this.row = 0;
		this.colum = 0;
		this.paquete = 0;
	endfunction

	function void print(input string tag = "");
		$display("---------------------------");
		$display("[TIME %g]", $time);
        $display("%s", tag);
		$display("ID Row = %d", this.row);
		$display("ID Colum = %d", this.colum);
		$display("Paquete = 0x%h",this.paquete);
		$display("---------------------------");
	endfunction

endclass

interface mesh_if #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}})
	(
		input clk
	);

	bit reset;
	bit pndng [ROWS*2+COLUMS*2];
	bit [pckg_sz-1:0] data_out [ROWS*2+COLUMS*2];
	bit popin [ROWS*2+COLUMS*2];
	bit pop [ROWS*2+COLUMS*2];
	bit [pckg_sz-1:0] data_out_i_in [ROWS*2+COLUMS*2];
	bit pndng_i_in [ROWS*2+COLUMS*2];
endinterface

//Defino los Mailboxes
typedef mailbox #(mesh_pckg #(.ROWS(4), .COLUMS(4), .pckg_sz(32), .fifo_depth(4), .bdcst({8{1'b1}}))) mesh_pckg_mbx; 	//Mailbox de tipo mesh_pckg
typedef mailbox #(sb_pckg #(.ROWS(4), .COLUMS(4), .pckg_sz(32), .fifo_depth(4), .bdcst({8{1'b1}})))sb_pckg_mbx; 		//Mailbox de tipo sb_pckg
typedef mailbox #(instrucciones) instr_pckg_mbx; 																		//Mailbox de tipo instrucciones
typedef mailbox #(path_pckg #(.ROWS(4), .COLUMS(4), .pckg_sz(32), .fifo_depth(4), .bdcst({8{1'b1}}))) path_pckg_mbx; 	//Mailbox de tipo path_pckg
