`timescale 1ns / 100ps

`define	NumBits	16
/*
`define	FUNC_ADD	4'b0000
`define	FUNC_SUB	4'b0001
`define FUNC_ID 	4'b0010
`define FUNC_NOT	4'b0011
`define	FUNC_AND	4'b0100
`define	FUNC_OR 	4'b0101
`define	FUNC_NAND	4'b0110
`define	FUNC_NOR	4'b0111
`define FUNC_XOR	4'b1000
`define FUNC_XNOR	4'b1001
`define	FUNC_LLS	4'b1010
`define	FUNC_LRS	4'b1011
`define	FUNC_ALS	4'b1100
`define	FUNC_ARS	4'b1101
`define	FUNC_TCP	4'b1110
`define	FUNC_ZERO	4'b1111
*/
module ALU (A, B, FuncCode, C, OverflowFlag);
	input [`NumBits-1:0] A; // 16bits A_input
	input [`NumBits-1:0] B; // 16bits B_input
	input [3:0] FuncCode; // 4bits logic
	output [`NumBits-1:0] C; // 16bits C_output
	output OverflowFlag;

	reg signed[`NumBits-1:0] C;
	reg OverflowFlag;

	// You can declare any variables as needed.
	// ADD = 4'b0000
	//`define SUB 4'b0001

	initial begin
		C = 0;
		OverflowFlag = 0;
	end   	

	// TODO: You should implement the functionality of ALU!
	// (HINT: Use 'always @(...) begin ... end')
	always @ (FuncCode or A or B) begin
		case(FuncCode)
		4'b0000: begin
   
   			C = A + B;
   			OverflowFlag = ((A[15] ^ C[15]) && (~(A[15] ^ B[15])) );
   			//~(A[15] ^ B[15]) is 1 if they have same sign and 0 otherwise
end

		4'b0001: begin
   
   			C = A - B;
   			OverflowFlag = ((A[15] ^ C[15]) && ((A[15] ^ B[15])) );
end
		4'b0010: C = A; // ok
		4'b0011: C = ~A; // ok
		4'b0100: C = A & B; // ok
		4'b0101: C = A | B; // ok
		4'b0110: C = ~(A & B); // ok
		4'b0111: C = ~(A | B); // ok
		4'b1000: C = A ^ B; // ok
		4'b1001: C = ~(A ^ B); // ok
		4'b1010: C = A << 1; // ok
		4'b1011: C = A >> 1; //ok
		4'b1100: C = A <<< 1; //ok
		4'b1101: if(A>=16'h8000) C = ((A >> 1) | (1 << 15));
			 else C = A >> 1; //ok
		4'b1110: C = ~A + 1; // ok
		4'b1111: C = 4'b0000; // ok

endcase
end
		

endmodule

