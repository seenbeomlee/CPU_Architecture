`include "opcodes.v"

module pc_adder(ID_EX_branch, target, ID_EX_pc, ID_EX_Sign_Extended_Imm);
	input ID_EX_branch;
	input [`WORD_SIZE-1:0] ID_EX_pc;
	input [`WORD_SIZE-1:0] ID_EX_Sign_Extended_Imm;

	output reg [`WORD_SIZE-1:0] target;

	always @(*) begin
		if(ID_EX_branch) begin
			target = ID_EX_pc + ID_EX_Sign_Extended_Imm;
		end
	end
endmodule