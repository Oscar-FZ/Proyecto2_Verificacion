
class mesh_pckg #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}});

	bit [7:0] nxt_jump;
	bit [3:0] t_row;
	bit [3:0] t_col;
	bit mode;
	bit [pckg_sz-18:0] pyld;
	bit [pckg_sz-1:0] paquete;

	rand int retardo;
	int tiempo;
	int max_retardo;
	bit [7:0]dir_env;
	bit [7:0]dir_rec;

	function new(bit [7:0] nxt_jump_n = 8'b0, bit [3:0] t_row_n = 4'b0, bit [3:0] t_col_n = 4'b0, bit mode_n = 1'b0, bit [pckg_sz-18:0] pyld_n = 0, int retardo_n = 5, int tiempo_n = 0, int max_retardo_n = 10, bit [7:0] dir_env_n = 0, bit [7:0] dir_rec_n = 0);
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
	endfunction

	task crea_paquetes();
		this.paquete = {this.nxt_jump, this.t_row, this.t_col, this.mode, this.pyld};
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

interface mesh_if #(parameter ROWS = 4, parameter COLUMS = 4, parameter pckg_sz = 32, parameter fifo_depth = 4, parameter bdcst = {8{1'b1}})
	(
		input clk
	);

	logic reset;
	logic pndng [ROWS*2+COLUMS*2];
	logic [pckg_sz-1:0] data_out [ROWS*2+COLUMS*2];
	logic popin [ROWS*2+COLUMS*2];
	logic pop [ROWS*2+COLUMS*2];
	logic [pckg_sz-1:0] data_out_i_in [ROWS*2+COLUMS*2];
	logic pndng_i_in [ROWS*2+COLUMS*2];
endinterface


typedef mailbox #(mesh_pckg #(.ROWS(4), .COLUMS(4), .pckg_sz(32), .fifo_depth(4), .bdcst({8{1'b1}}))) mesh_pckg_mbx;

