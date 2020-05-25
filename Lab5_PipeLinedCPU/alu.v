`include "opcodes.v"

`define	NumBits	16

module alu (OpCode, A, B, funcCode, C);
	input [`NumBits-1:0] A;
	input [`NumBits-1:0] B;
	input [5:0] funcCode;
	input [3:0] OpCode;
	output [`NumBits-1:0] C;

	reg [`NumBits-1:0] C;

	initial begin
		C = 0;
	end   	
	
always @(*) begin
            if (OpCode == 15) begin // R Type
               case (funcCode)
                  `FUNC_ADD: begin C = (A + B); end // ok
                  `FUNC_SUB: begin C = (A - B); end // ok
                  `FUNC_AND: begin C = (A & B); end // ok
                  `FUNC_ORR: begin C = (A | B); end // ok
                  `FUNC_NOT: begin C = ~A; end // ok
                  `FUNC_TCP: begin C = (~A + 1); end // ok
                  `FUNC_SHL: begin C = (A << 1); end // ok
                  `FUNC_SHR: begin C = (A >> 1); end // ok
               endcase
            end
            else begin // I Type
              case (OpCode)
                  `ADI_OP: begin C = (A + B); end // ok
                  `ORI_OP: begin C = (A | B); end // ok
                  `LHI_OP: begin C = (A << 8); end // ok
                  `LWD_OP: begin C = (A + B) ; end // ok
		            `SWD_OP: begin C = (A + B); end // ok
		            `JAL_OP: begin C = (A + B); end // ok
         	  default: begin C = (A + B); end // not yet (nothing)
               endcase
            end
	end
endmodule