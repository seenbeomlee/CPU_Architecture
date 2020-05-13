`include"opcodes.v"

module control(Op_Code, JAL, branch, MemRead, MemWrite, ALUSrc, RegWrite, MemtoReg, Func_Code, operand_rs, operand_rt, Sign_Extend_Immediate, A, B, IRWrite, JALR);
    input [3:0] Op_Code;
    input [5:0] Func_Code;
    input [`WORD_SIZE-1:0] operand_rs;
    input [`WORD_SIZE-1:0] operand_rt;
    input [`WORD_SIZE-1:0] Sign_Extend_Immediate;
    input IRWrite;

    output reg [`WORD_SIZE-1:0] A;
    output reg [`WORD_SIZE-1:0] B;
    output reg JAL;
    output reg branch;
    output reg MemRead;
    output reg MemWrite;
    output reg ALUSrc;
    output reg RegWrite;
    output reg MemtoReg;
    output reg JALR; 

    wire rtype;
    wire itype;
    wire lw;
    wire sw;
    wire br;
    wire jp;

    assign rtype = (Op_Code == 15);
    assign itype = (Op_Code <= 8);
    assign lw = (Op_Code == 7);
    assign sw = (Op_Code == 8);
    assign br = (Op_Code <= 3);
    assign jp = (Op_Code == 9 || Op_Code == 10);

    initial begin
        JAL <= 0;
        branch <= 0;
        MemRead <= 0;
        MemWrite <= 0;
        ALUSrc <= 0;
        RegWrite <= 0;
        MemtoReg <= 0;
	A <= operand_rs;
        B <= operand_rt;
	JALR <= 0;
    end

    // control A, B and conditions for output
    always @(*) begin
        JAL = jp;
        branch = br;
        MemWrite = sw;
        ALUSrc = itype;
        RegWrite = ~(br | sw) && (Func_Code != `INST_FUNC_WWD && Func_Code != `INST_FUNC_JPR && Func_Code != `INST_FUNC_HLT && Op_Code != `JMP_OP);			
        MemtoReg = lw;
        MemRead = lw;
	if(IRWrite) begin
		JALR = 0; // set JALR 0 (JALR == 1 only at JRL and JPR
	end
    end
    always @(*) begin
        case (Op_Code)
            `ALU_OP: begin
                    case (Func_Code)
                        `FUNC_ADD: begin A = operand_rs; B = operand_rt; end // ALU
                        `FUNC_SUB: begin A = operand_rs; B = operand_rt; end // ALU
                        `FUNC_AND: begin A = operand_rs; B = operand_rt; end // ALU
                        `FUNC_ORR: begin A = operand_rs; B = operand_rt; end // ALU
                        `FUNC_NOT: begin A = operand_rs; B = operand_rt; end // ALU
                        `FUNC_TCP: begin A = operand_rs; B = operand_rt; end // ALU
                        `FUNC_SHL: begin A = operand_rs; B = 1; end
                        `FUNC_SHR: begin A = operand_rs; B = 1; end
			////////////////////////////////////////////////////////////////////
                        `INST_FUNC_JRL: begin A = operand_rs; B = operand_rt; JALR = 1; end // JRL
			`INST_FUNC_JPR: begin A = operand_rs; B = operand_rt; JALR = 1; end // JPR
                        default: begin A = operand_rs; B = operand_rt; end // WWD and HALT
                    endcase
                end
            `ADI_OP: begin A = operand_rs; B = Sign_Extend_Immediate; end //ALU
            `ORI_OP: begin A = operand_rs; B = Sign_Extend_Immediate; end //ALU
            `LHI_OP: begin A = Sign_Extend_Immediate; B = 8; end //ALU
            `LWD_OP: begin A = operand_rs; B = Sign_Extend_Immediate; end //ALU
            `SWD_OP: begin A = operand_rs; B = Sign_Extend_Immediate; end //ALU
            `JAL_OP: begin A = operand_rs; B = Sign_Extend_Immediate; end
	    `BNE_OP: begin A = operand_rs; B = operand_rt; end //ALU
	    `BEQ_OP: begin A = operand_rs; B = operand_rt; end //ALU
	    `BGZ_OP: begin A = operand_rs; B = operand_rt; end //ALU
	    `BLZ_OP: begin A = operand_rs; B = operand_rt; end //ALU
            default: begin A = operand_rs; B = Sign_Extend_Immediate; end
        endcase 
    end

endmodule

