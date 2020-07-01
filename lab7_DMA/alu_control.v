`include "opcodes.v"

module alu_control(Sign_Extend_Imm, A, B, IF_ID_Instruction, forwardA, forwardB, ID_EX_Sign_Extend_Imm, ID_EX_Operand_Rs, ID_EX_Operand_Rt, EX_MEM_WB, WB, ID_EX_Op_Code, ID_EX_Func_Code, ID_EX_Branch);

	input [`WORD_SIZE-1:0] IF_ID_Instruction;
	input [1:0] forwardA;
	input [1:0] forwardB;
	input [5:0] ID_EX_Func_Code;
	input [3:0] ID_EX_Op_Code;
	input ID_EX_Branch;
	input [`WORD_SIZE-1:0] ID_EX_Sign_Extend_Imm;
	input [`WORD_SIZE-1:0] ID_EX_Operand_Rs, ID_EX_Operand_Rt;
	input [`WORD_SIZE-1:0] EX_MEM_WB, WB;


	output reg [`WORD_SIZE-1:0] Sign_Extend_Imm;
	output reg [`WORD_SIZE-1:0] A; 
	output reg [`WORD_SIZE-1:0] B; 

	always @(*) begin

		/* for Sign_Extend_Imm */
		if(IF_ID_Instruction[7] == 1) begin
			Sign_Extend_Imm <= {8'hff, IF_ID_Instruction[7:0]};
		end
		else if(IF_ID_Instruction[7] == 0) begin
			Sign_Extend_Imm <= {8'h00, IF_ID_Instruction[7:0]};
		end

		/* for A */
		if(forwardA == 2'b00) begin
			if(ID_EX_Op_Code == `LHI_OP) A <= ID_EX_Sign_Extend_Imm;
			else A <= ID_EX_Operand_Rs;
		end
		else begin
			if(forwardA == 2'b01) A <= WB;
			else A <= EX_MEM_WB;
		end

		/* for B */
		if(ID_EX_Op_Code <= 8 && ~ID_EX_Branch) begin B <= ID_EX_Sign_Extend_Imm; end
		else if(ID_EX_Op_Code == 15 && ID_EX_Func_Code == `INST_FUNC_SHL || ID_EX_Func_Code == `INST_FUNC_SHR) begin B <= 1; end 
		else if(ID_EX_Op_Code == `LHI_OP) begin B <= 8; end
		else begin
			if (forwardB == 2'b00) B <= ID_EX_Operand_Rt;
			else if (forwardB == 2'b01) B <= WB;
			else B <= EX_MEM_WB;
		end

	end

endmodule