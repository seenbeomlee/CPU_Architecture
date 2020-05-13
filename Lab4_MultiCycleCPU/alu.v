`include "opcodes.v"
module alu(Op_Code, A, B, Func_Code, C, bcond);

      input [3:0] Op_Code;
      input [5:0] Func_Code;
      input [`WORD_SIZE-1:0] A; // 16bits A_input
      input [`WORD_SIZE-1:0] B; // 16bits B_input
      output reg [`WORD_SIZE-1:0] C; // 16bits C_output
      output reg bcond; // 1bit branch condition for Bxx

      initial begin
         C = 0;
         bcond = 0;
      end      


      always @(*) begin
            if (Op_Code == 15) begin // R Type
               case (Func_Code)
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
              case (Op_Code)
                  `ADI_OP: begin C = (A + B); end // ok
                  `ORI_OP: begin C = (A | B); end // ok
                  `LHI_OP: begin C = (A << 8); end // ok
                  `LWD_OP: begin C = (A + B) ; end // ok
		  `SWD_OP: begin C = (A + B); end // ok
		  `JAL_OP: begin C = (A + B); end // ok
         	  default: begin C = (A + B); end // not yet (nothing)
               endcase
            end
     	 // Branch Condition Determination
            case (Op_Code)
            `BNE_OP: bcond = ((A != B) ? 1 : 0); //ok
            `BEQ_OP: bcond = ((A == B) ? 1 : 0); //ok
            `BGZ_OP: bcond = ((A[15] == 0 && A > 0) ? 1 : 0); //ok
            `BLZ_OP: bcond = ((A[15] == 1) ? 1 : 0); //ok
            default: begin bcond = 0; end
            endcase
         end
endmodule 