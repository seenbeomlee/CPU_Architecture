`include "opcodes.v"

module branch_control (A, B, bcond, ID_EX_Op_Code, ID_EX_Branch);
	input [`WORD_SIZE-1:0] A;
	input [`WORD_SIZE-1:0] B;
	input [3:0] ID_EX_Op_Code;
	input ID_EX_Branch;

	output reg bcond;
	
	always @(*) begin
		if(ID_EX_Branch) begin
			case(ID_EX_Op_Code)
				`BNE_OP: bcond = ((A != B) ? 1 : 0); //ok
				`BEQ_OP: bcond = ((A == B) ? 1 : 0); //ok
				`BGZ_OP: bcond = ((A[15] == 0 && A > 0) ? 1 : 0); //ok
				`BLZ_OP: bcond = ((A[15] == 1) ? 1 : 0); //ok
				default: bcond = 0;
			endcase
		end
	end
endmodule