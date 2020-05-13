`timescale 1ns/1ns
`include "opcodes.v" 	   

module cpu(clk, reset_n, readM, writeM, address, data, num_inst, output_port, is_halted);
	input clk; // clock signal
	input reset_n; // reset your CPU (registers, PC, etc)  
	output readM; // "read" signal to memory   
	output writeM; // "write" signal to memory  
	output reg [`WORD_SIZE-1:0] address; // target memory address
	inout [`WORD_SIZE-1:0] data; // data for reading or writing (can be used as both input and output) 
	output reg [`WORD_SIZE-1:0] num_inst; // number of instruction during execution (for debuging & testing purpose)
	output [`WORD_SIZE-1:0] output_port; // this will be used for a "WWD" instruction
	output is_halted;

	reg [`WORD_SIZE-1:0] pc, next_pc; // pc value
	reg [1:0] rs, rt, rd, wr; //register index
	reg [`WORD_SIZE-1:0] Write_Back_Register; //write register value
	reg [3:0] Op_Code; //operation code
	reg [5:0] Func_Code; //function code
	reg [7:0] Immediate; //Immediateediate value
	reg [`WORD_SIZE-1:0] Sign_Extend_Immediate; //sign extension
	reg [11:0] Target_Address; //jump address

	/* ALU operands */
	wire [`WORD_SIZE-1:0] operand_rs, operand_rt;
	wire [`WORD_SIZE-1:0] A, B;
	wire [`WORD_SIZE-1:0] C;
	wire bcond; // branch condition

	reg [`WORD_SIZE-1:0] Instruction_Or_Data_Reg;

	reg [`WORD_SIZE-1:0] regs[`NUM_REGS-1:0];//register file
	assign operand_rs = regs[rs];
	assign operand_rt = regs[rt];

	wire JAL, branch, MemRead, MemWrite, ALUSrc, RegWrite, MemtoReg;
	wire PvsWriteEn, IorD, IRWrite, JALR;

	assign output_port = (Op_Code == 15 && Func_Code == `INST_FUNC_WWD) ? operand_rs : 0; 
	assign is_halted = (Op_Code == 15) && (Func_Code == `INST_FUNC_HLT);

	assign data = IorD ? operand_rt : `WORD_SIZE'bz;
	
	control CONTROL(.Op_Code(Op_Code), .JAL(JAL), .branch(branch), .MemRead(MemRead), .MemWrite(MemWrite), .ALUSrc(ALUSrc),
	 .RegWrite(RegWrite), .MemtoReg(MemtoReg), .Func_Code(Func_Code), .operand_rs(operand_rs), .operand_rt(operand_rt), .Sign_Extend_Immediate(Sign_Extend_Immediate), .A(A), .B(B),
	 .IRWrite(IRWrite), .JALR(JALR));
	
	state_control STATE_CONTROL(.clk(clk), .reset_n(reset_n) ,.JAL(JAL), .branch(branch), .MemRead(MemRead), .MemWrite(MemWrite),
	 .readM(readM), .writeM(writeM) ,.PvsWriteEn(PvsWriteEn), .IorD(IorD), .IRWrite(IRWrite));

	alu ALU(Op_Code, A, B, Func_Code, C , bcond);

	initial begin
		pc <= 0;
		num_inst <= 0;
		next_pc <= 0;
		Op_Code <= 0;
		Func_Code <= 0;
		Immediate <= 0;
		Sign_Extend_Immediate <= 0;
		Target_Address <= 0;
		regs[0] <= 0;
		regs[1] <= 0;
		regs[2] <= 0;
		regs[3] <= 0;
	end
	
	always @(*) begin
		if(readM) begin
			Instruction_Or_Data_Reg = data;
		end

		if((MemRead & ~IRWrite & readM) | (MemWrite & ~IRWrite & writeM)) address = C;
		else address = pc;

		//Write instruction register
		if(IRWrite) begin
			Op_Code = Instruction_Or_Data_Reg[`WORD_SIZE-1:12];
			Target_Address = {pc[15:12], Instruction_Or_Data_Reg[11:0]};
			rs = Instruction_Or_Data_Reg[11:10];
			rt = Instruction_Or_Data_Reg[9:8];
			rd = Instruction_Or_Data_Reg[7:6];
			Func_Code = Instruction_Or_Data_Reg[5:0];
			Immediate = Instruction_Or_Data_Reg[7:0];
			if(Immediate[7] == 1) Sign_Extend_Immediate = {8'hff, Immediate};
			else Sign_Extend_Immediate = {8'h00, Immediate};
		end
		//jump control

		if(Op_Code == `JAL_OP || Func_Code == `INST_FUNC_JRL) rd = 2;

		wr = ALUSrc ? rt : rd;

		if(Op_Code == 10 || Func_Code == 26) Write_Back_Register = pc + 1;//JAL or JRL instruction
      		else if(MemtoReg == 1) Write_Back_Register = Instruction_Or_Data_Reg;//Read Data Memory
      		else Write_Back_Register = C;//ALU output

		if(JALR == 1) next_pc = operand_rs;//return from procedure
		else if(JAL == 1) next_pc = Target_Address;//jump to address
		else if(bcond == 1) next_pc = pc + Sign_Extend_Immediate + 1;//branch taken
		else next_pc = pc + 1;//ordinary case, just increment pc
	end

	always @(posedge clk) begin
		if(!reset_n) begin
			pc <= 0;
			num_inst <= 0;
			next_pc <= 0;
			Op_Code <= 0;
			Func_Code <= 0;
			Immediate <= 0;
			Sign_Extend_Immediate <= 0;
			Target_Address <= 0;
		end
		else begin
			/* pc UPDATE */
			if(PvsWriteEn) begin
				pc <= next_pc;
				num_inst <= num_inst + 1;
			end
			/* register UPDATE */
    			if(RegWrite && PvsWriteEn) begin
    				regs[wr] <= Write_Back_Register;
    			end
		end
	end
endmodule

