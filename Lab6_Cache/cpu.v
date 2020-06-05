`timescale 1ns/1ns
`include "opcodes.v"

module cpu(Clk, Reset_N, finish, readM1, address1, data1, readM2, writeM2, address2, data2, num_inst, output_port, is_halted);
/* initial variables */
	input Clk;
	wire Clk;
	input Reset_N;
	wire Reset_N;

	output reg readM1;
	output [`WORD_SIZE-1:0] address1;
	wire [`WORD_SIZE-1:0] address1;
	output readM2;
	wire readM2;
	output writeM2;
	wire writeM2;
	output [`WORD_SIZE-1:0] address2;
	wire [`WORD_SIZE-1:0] address2;

	input [`WORD_SIZE-1:0] data1;
	wire [`WORD_SIZE-1:0] data1;
	inout [`WORD_SIZE-1:0] data2;
	wire [`WORD_SIZE-1:0] data2;
/* modified */
	input finish;
	wire finish;
	reg [`WORD_SIZE-1:0] ex_mem_A, mem_wb_A;
/* modified */

	output [`WORD_SIZE-1:0] num_inst;
	wire [`WORD_SIZE-1:0] num_inst;
	output [`WORD_SIZE-1:0] output_port;
	wire [`WORD_SIZE-1:0] output_port;
	output is_halted;
	wire is_halted;

	reg [`WORD_SIZE-1:0] pc, next_pc;
	wire [`WORD_SIZE-1:0] target;

	reg is_stall;
	wire bcond;
/* initial variables */

	/* ALU */
	wire [`WORD_SIZE-1:0] A, B, C, Sign_Extended_Imm;
	
	/* Register */
	wire[1:0] rs, rt;
	wire [`WORD_SIZE-1:0] EX_MEM_wb, wb;
	wire [`WORD_SIZE-1:0] operand_rs, operand_rt;
	reg [`WORD_SIZE-1:0] regs[`NUM_REGS-1:0];

	/* Control */ 
	reg flush;
	wire current_is_halted;
	wire [20:0] signal;
	reg [20:0] ID_EX_signal;
	reg [6:0] EX_MEM_signal;
	reg [4:0] mem_wb_signal;

	//Forwarding
	wire [1:0] forwardA;
	wire [1:0] forwardB;

	//branch Predictor
	wire [`WORD_SIZE-1:0] predict_pc;
	reg [`WORD_SIZE-1:0] branch_target;


	reg [`WORD_SIZE-1:0] pc_num_inst;

	/* IF_ID_reg */
	reg [`WORD_SIZE-1:0] IF_ID_num_inst;
	reg [`WORD_SIZE-1:0] IF_ID_pc;

	reg [`WORD_SIZE-1:0] IF_ID_instruction;

	reg [`WORD_SIZE-1:0] IF_ID_predict_pc;

	/* ID_EX_reg */
	reg [`WORD_SIZE-1:0] ID_EX_num_inst;
	reg [`WORD_SIZE-1:0] ID_EX_jump_target_address;
	reg [`WORD_SIZE-1:0] ID_EX_pc;
	
	reg ID_EX_is_halted;
	reg [`WORD_SIZE-1:0] ID_EX_Sign_Extended_Imm;
	reg [1:0] ID_EX_rd, ID_EX_rt, ID_EX_rs;

	reg [`WORD_SIZE-1:0] ID_EX_operand_rs, ID_EX_operand_rt;

	reg [`WORD_SIZE-1:0] ID_EX_predict_pc;

	/* EX_MEM_reg */
	reg [`WORD_SIZE-1:0] EX_MEM_pc;

	reg [`WORD_SIZE-1:0] EX_MEM_alu_result;

	reg [`WORD_SIZE-1:0] EX_MEM_operand_rt;

	/* MEM_WB_reg */
	reg [`WORD_SIZE-1:0] mem_wb_pc;

	reg [`WORD_SIZE-1:0] mem_wb_alu_result;

	reg [`WORD_SIZE-1:0] mem_wb_read_data;

	wire [3:0] IF_ID_Op_Code;
	wire [5:0] IF_ID_Func_Code;
	wire use_rs;
	wire use_rt;

	/* for load-use hazard */
	assign IF_ID_Func_Code = IF_ID_instruction[5:0];
	assign IF_ID_Op_Code = IF_ID_instruction[15:12];
	assign use_rs = (IF_ID_Op_Code != 6) && (IF_ID_Op_Code != 9) && (IF_ID_Op_Code != 10);
	assign use_rt = (IF_ID_Op_Code == 7) || (IF_ID_Op_Code == 8) || (IF_ID_Op_Code == 0) || (IF_ID_Op_Code == 1) || ( (IF_ID_Op_Code == 15) && ( (IF_ID_Func_Code == 0) || (IF_ID_Func_Code == 1) || (IF_ID_Func_Code == 2) || (IF_ID_Func_Code == 3) ));

	/* wires */
	assign address1 = pc;
	assign data1 = `WORD_SIZE'bz;
	assign data2 = EX_MEM_signal[4] ? EX_MEM_operand_rt : `WORD_SIZE'bz; 
	assign output_port = ID_EX_signal[3] ? mem_wb_A : 0; 
	assign is_halted = ID_EX_is_halted;
	assign num_inst = ID_EX_num_inst;

	/* regfile */
	assign rs = IF_ID_instruction[11:10];
	assign rt = IF_ID_instruction[9:8];
	assign EX_MEM_wb = EX_MEM_signal[0] ? EX_MEM_pc : EX_MEM_alu_result;
	assign wb = mem_wb_signal[1] ? mem_wb_read_data : mem_wb_signal[0] ? mem_wb_pc : mem_wb_alu_result;

	/* internal forwarding */
	assign operand_rs = (mem_wb_signal[2] && (rs) == mem_wb_signal[4:3]) ? wb : regs[rs];
	assign operand_rt = (mem_wb_signal[2] && (rt) == mem_wb_signal[4:3]) ? wb : regs[rt];

	/* memory data */
	assign address2 = EX_MEM_alu_result;
	assign readM2 = EX_MEM_signal[3];
	assign writeM2 = EX_MEM_signal[4];
	
	alu ALU(.OpCode(ID_EX_signal[20:17]), .A(A), .B(B), .funcCode(ID_EX_signal[16:11]), .C(C));

	alu_control ALU_CONTROL(
		.Sign_Extend_Imm(Sign_Extended_Imm),
		.A(A), 
		.B(B),
		.IF_ID_Instruction(IF_ID_instruction),
		.forwardA(forwardA),
		.forwardB(forwardB),
		.ID_EX_Sign_Extend_Imm(ID_EX_Sign_Extended_Imm),
		.ID_EX_Operand_Rs(ID_EX_operand_rs),
		.ID_EX_Operand_Rt(ID_EX_operand_rt),
		.EX_MEM_WB(EX_MEM_wb),
		.WB(wb),
		.ID_EX_Op_Code(ID_EX_signal[20:17]),
		.ID_EX_Func_Code(ID_EX_signal[16:11]),
		.ID_EX_Branch(ID_EX_signal[0])
);

	control CONTROL(
		.instruction(IF_ID_instruction), 
		.flush(flush),
		.signal(signal),
		.Is_Halted(current_is_halted)
	);
	data_hazard_unit DATA_HAZARD_UNIT(
		.ID_EX_rs(ID_EX_rs),
		.ID_EX_rt(ID_EX_rt),
		.EX_MEM_rd(EX_MEM_signal[6:5]),
		.MEM_WB_rd(mem_wb_signal[4:3]),
		.RegWrite_MEM(EX_MEM_signal[2]),
		.RegWrite_WB(mem_wb_signal[2]),
		.ForwardA(forwardA),
		.ForwardB(forwardB)
	);

	Branch_Predictor BRANCH_PREDICTOR(
		.clk(Clk),
		.IF_PC(pc),
		.IF_predict_pc(predict_pc),
		.ID_PC(ID_EX_pc - 16'b1),
		.branch(ID_EX_signal[0]),
		.jump(ID_EX_signal[2] || ID_EX_signal[1]),
		.target(branch_target)
	);
	branch_control BRANCH_CONTROL(
		.A(A),
		.B(B),
		.bcond(bcond),
		.ID_EX_Op_Code(ID_EX_signal[20:17]),
		.ID_EX_Branch(ID_EX_signal[0])
	);
	pc_adder PC_ADDER(
		.ID_EX_branch(ID_EX_signal[0]),
		.target(target),
		.ID_EX_pc(ID_EX_pc),
		.ID_EX_Sign_Extended_Imm(ID_EX_Sign_Extended_Imm)
	);

	initial begin
		pc <= 0;
		next_pc <= 0;
		pc_num_inst <= 0;
		readM1 <= 0;
		flush <= 0;
		ID_EX_signal[8] <= 0;
		EX_MEM_signal[4] <= 0;
		ID_EX_signal[6] <= 0;
		EX_MEM_signal[2] <= 0;
		mem_wb_signal[2] <= 0;
		regs[0] <= 0;
		regs[1] <= 0;
		regs[2] <= 0;
		regs[3] <= 0;
	end

	always @(*) begin

		is_stall = ((rs == ID_EX_signal[10:9] && (use_rs)) || (rt == ID_EX_signal[10:9] && (use_rt))) && ID_EX_signal[7];
		if (ID_EX_signal[2] && (ID_EX_predict_pc != ID_EX_jump_target_address)) is_stall = 1;
		else if (ID_EX_signal[1]  && (ID_EX_predict_pc != A)) is_stall = 1;
		else if (ID_EX_signal[0] && bcond && (ID_EX_predict_pc != target)) is_stall = 1;
		else if (ID_EX_signal[0] && ~bcond && (ID_EX_predict_pc != ID_EX_pc)) is_stall = 1;
		$display("rs: %d, rt: %d, dest: %d, Load?: %d, is_stall?: %d, IF_ID_Op_Code: %d, IF_ID_Func_Code: %d, output: %h", rs, rt, ID_EX_signal[10:9], ID_EX_signal[7], is_stall, IF_ID_Op_Code, IF_ID_Func_Code, output_port);
		

		next_pc = predict_pc;

		if (ID_EX_signal[2]) begin
			branch_target = ID_EX_jump_target_address;
		end
		else if (ID_EX_signal[1]) begin
			branch_target = A;
		end
		else if (ID_EX_signal[0] && bcond) begin
			branch_target = target;
		end
	end

	always @(posedge Clk) begin

		if(!Reset_N) begin
			pc <= 0;
			next_pc <= 0;
			pc_num_inst <= 0;
			readM1 <= 0;
			flush <= 0;
			ID_EX_signal[8] <= 0;
			EX_MEM_signal[4] <= 0;
			ID_EX_signal[6] <= 0;
			EX_MEM_signal[2] <= 0;
			mem_wb_signal[2] <= 0;

			regs[0] <= 0;
			regs[1] <= 0;
			regs[2] <= 0;
			regs[3] <= 0;
		end
/* modified */
		else if(finish) begin
/* modified */
			if(mem_wb_signal[2]) begin
    			regs[mem_wb_signal[4:3]] <= wb;
    		end

			readM1 <= 1;
			if (ID_EX_signal[2]&& (ID_EX_predict_pc != ID_EX_jump_target_address)) begin
				pc <= ID_EX_jump_target_address;
			end
			else if (ID_EX_signal[1] && (ID_EX_predict_pc != A)) begin
				pc <= A;
			end
			else if (ID_EX_signal[0] && bcond && (ID_EX_predict_pc != target)) begin
				pc <= target;
			end
			else if (ID_EX_signal[0] && ~bcond && ID_EX_predict_pc != ID_EX_pc) begin
				pc <= ID_EX_pc;
			end
			else if(current_is_halted) begin
				readM1 <= 0;
			end
			else if (((rs == ID_EX_signal[10:9] && (use_rs)) || (rt == ID_EX_signal[10:9] && (use_rt))) && ID_EX_signal[7]) begin
				pc <= ID_EX_pc;
			end
			else begin
				pc <= next_pc;
				pc_num_inst <= pc_num_inst + 1;
			end

			//pipeline pc
			IF_ID_pc <= pc + 1;
			IF_ID_instruction <= data1;
			IF_ID_predict_pc <= predict_pc;

			if(is_stall) begin
				flush <= 1;

				/* ID_EX_pc <= ID_EX_pc; */
				ID_EX_predict_pc <= 0;

				ID_EX_rd <= 0;
				ID_EX_rt <= 0;
				ID_EX_rs <= 0;
				ID_EX_operand_rs <= 0;
				ID_EX_operand_rt <= 0;
				ID_EX_Sign_Extended_Imm <= 0;
				ID_EX_is_halted <= 0;

				pc_num_inst <= IF_ID_num_inst;
				IF_ID_num_inst <= ID_EX_num_inst;
				ID_EX_num_inst <= ID_EX_num_inst;
				ID_EX_signal <= 21'b0;
			end
			else begin
				flush <= 0;
				IF_ID_num_inst <= pc_num_inst;

				ID_EX_pc <= IF_ID_pc;
				ID_EX_predict_pc <= IF_ID_predict_pc;

				ID_EX_jump_target_address <= {IF_ID_pc[15:12], IF_ID_instruction[11:0]};

				ID_EX_rd <= IF_ID_instruction[7:6];
				ID_EX_rt <= rt;
				ID_EX_rs <= rs;
				ID_EX_operand_rs <= operand_rs;
				ID_EX_operand_rt <= operand_rt;
				ID_EX_Sign_Extended_Imm <= Sign_Extended_Imm;
				ID_EX_is_halted <= current_is_halted;

				ID_EX_num_inst <= IF_ID_num_inst;
				ID_EX_signal <= signal;
			end

ex_mem_A <= A;
			EX_MEM_pc <= ID_EX_pc;
			EX_MEM_alu_result <= C;
			EX_MEM_operand_rt <= ID_EX_operand_rt;

			EX_MEM_signal <= ID_EX_signal[10:4];

mem_wb_A <= ex_mem_A;
			mem_wb_pc <= EX_MEM_pc;

			mem_wb_alu_result <= EX_MEM_alu_result;
			mem_wb_read_data <= data2;

			mem_wb_signal <= {EX_MEM_signal[6:5], EX_MEM_signal[2:0]};

		end
	end
endmodule