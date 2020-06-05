`include "opcodes.v"

module control(instruction, flush, signal, Is_Halted);
    input [`WORD_SIZE-1:0] instruction;
    input flush;

    reg [3:0] Op_Code;
	output wire [20:0] signal;
    reg [5:0] Func_Code;
    reg [1:0] Reg_Dest;
    reg Mem_Write;
    reg Mem_Read;
    reg Reg_Write;
    reg Mem_to_Reg;
    reg Pc_to_Reg;
    output reg Is_Halted;
    reg Is_WWD;
    reg J_Type_Jump;
    reg R_Type_Jump;
    reg branch;
    

    wire R_Type, I_type, J_Type, Load, Store;

    assign R_Type = (Op_Code == 15);
    assign I_type = (Op_Code <= 8);
    assign J_Type = (Op_Code== 9 || Op_Code == 10);
    assign Load = (Op_Code == 7);
    assign Store = (Op_Code == 8);

	assign signal = {Op_Code, Func_Code, Reg_Dest, Mem_Write, Mem_Read, Reg_Write, Mem_to_Reg, Pc_to_Reg, Is_WWD, J_Type_Jump, R_Type_Jump, branch};

    initial begin

        Func_Code <= 0;
        Reg_Dest <= 0;
        Mem_Write <= 0;
        Mem_Read <= 0;
        Reg_Write <= 0;
        Mem_to_Reg <= 0;
        Pc_to_Reg <= 0;
        Is_Halted <= 0;
        Is_WWD <= 0;
        J_Type_Jump <= 0;
        R_Type_Jump <= 0;
    end

 
    always @(*) begin
        if(!flush) begin

		Op_Code = instruction[15:12];
		Func_Code = instruction[5:0];

	    branch = (Op_Code <= 3);
            Mem_Read = Load;
            Mem_to_Reg = Load;
            Mem_Write = Store;
            Is_Halted = R_Type && Func_Code == `INST_FUNC_HLT;
            Is_WWD = R_Type && Func_Code == `INST_FUNC_WWD;
            J_Type_Jump = J_Type;
            R_Type_Jump = (R_Type && Func_Code == `INST_FUNC_JPR) || (R_Type && Func_Code == `INST_FUNC_JRL);            
            Pc_to_Reg = (Op_Code == `JAL_OP) || (R_Type && Func_Code == `INST_FUNC_JRL);
            Reg_Write = ~(branch | Store) && (Func_Code != `INST_FUNC_WWD && Func_Code != `INST_FUNC_JPR && Func_Code != `INST_FUNC_HLT && Op_Code != `JMP_OP);
           
            if(Pc_to_Reg) 
                Reg_Dest = 2'b10; //$2
            else if (I_type)
                Reg_Dest = instruction[9:8]; //$rt
            else   
                Reg_Dest = instruction[7:6]; //$rd

            case (Op_Code)
                `ALU_OP: begin
                    case (Func_Code)
                        `INST_FUNC_ADD: Func_Code = `FUNC_ADD;
                        `INST_FUNC_SUB: Func_Code = `FUNC_SUB;
                        `INST_FUNC_AND: Func_Code = `FUNC_AND;
                        `INST_FUNC_ORR: Func_Code = `FUNC_ORR;
                        `INST_FUNC_NOT: Func_Code = `FUNC_NOT;
                        `INST_FUNC_TCP: Func_Code = `FUNC_TCP;
                        `INST_FUNC_SHL: Func_Code = `FUNC_SHL;
                        `INST_FUNC_SHR: Func_Code = `FUNC_SHR;
                    endcase
                end
            endcase
        end

        else begin
            Func_Code = 0;
            Reg_Dest = 0;
            Mem_Write = 0;
            Mem_Read = 0;
            Reg_Write = 0;
            Mem_to_Reg = 0;
            Pc_to_Reg = 0;
            Is_Halted = 0;
            Is_WWD = 0;
            J_Type_Jump = 0;
            R_Type_Jump = 0;
            branch = 0;
        end 
    end


endmodule
