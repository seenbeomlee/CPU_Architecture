`include "opcodes.v"

`define N_bit 8
`define BTB_SIZE 256

module Branch_Predictor(clk, IF_PC, IF_predict_pc, ID_PC, branch, jump, target);
	
	input clk;
	input [`WORD_SIZE-1:0] IF_PC;
	input [`WORD_SIZE-1:0] ID_PC;
	input branch;
	input jump;
	input [`WORD_SIZE-1:0] target;

	output reg [`WORD_SIZE-1:0] IF_predict_pc;

	
	reg [`WORD_SIZE-1-`N_bit:0] Tag_Table [`BTB_SIZE-1:0];
	reg [`WORD_SIZE-1:0] BTB [`BTB_SIZE-1:0];

	
	wire [`WORD_SIZE-`N_bit-1:0] IF_Tag = IF_PC[`WORD_SIZE-1:`WORD_SIZE-`N_bit];
	wire [`N_bit-1:0] IF_Index = IF_PC[`N_bit-1 :0];
	
	
	wire [`WORD_SIZE-`N_bit-1:0] ID_Tag = ID_PC[`WORD_SIZE-1:`WORD_SIZE-`N_bit];
	wire [`N_bit-1:0] ID_Index = ID_PC[`N_bit-1:0];
	

	initial begin
		IF_predict_pc <= 0;
	end
	
	always @(*) begin
		
		IF_predict_pc = IF_PC + 1;

		if(IF_Tag == Tag_Table[IF_Index]) begin
			IF_predict_pc = BTB[IF_Index];
		end	

	end

	always @(posedge clk) begin

		if(branch || jump) begin
			Tag_Table[ID_Index] <= ID_Tag;
			BTB[ID_Index] <= target;
		end

	end
endmodule


