
`include "opcodes.v"

module data_hazard_unit(ID_EX_rs, ID_EX_rt, EX_MEM_rd, MEM_WB_rd, RegWrite_MEM, RegWrite_WB, ForwardA, ForwardB);
	input [1:0] ID_EX_rs;
	input [1:0] ID_EX_rt;
	input [1:0] EX_MEM_rd;
	input [1:0] MEM_WB_rd;
	input RegWrite_MEM;
	input RegWrite_WB;
	output reg [1:0] ForwardA;
	output reg [1:0] ForwardB;

	/* WB -> MEM forwarding */

	always @(*) begin
		/* Rs data hazard */
		if ((ID_EX_rs == MEM_WB_rd) && RegWrite_WB) begin
			ForwardA = 2'b01;
		end
		else if ((ID_EX_rs == EX_MEM_rd) && RegWrite_MEM) begin
			ForwardA = 2'b10;
		end
		else
			ForwardA = 2'b00;

		/* Rt data hazard */
		if ((ID_EX_rt == MEM_WB_rd) && RegWrite_WB) begin
			ForwardB = 2'b01;
		end
		else if ((ID_EX_rt == EX_MEM_rd) && RegWrite_MEM) begin
			ForwardB = 2'b10;
		end

		else
			ForwardB = 2'b00;
	end
endmodule