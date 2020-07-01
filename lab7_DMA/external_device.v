`timescale 1ns/1ns	

`define WORD_SIZE 16

module external_device (clk, external_data0, external_data1, external_data2, external_data3, BG, offset, start_interrupt);
	
	/* input */
	input clk;
	wire clk;
	input BG;    
	input [`WORD_SIZE-1:0] offset;  
    
	/* input */
	output reg start_interrupt;
	output reg [`WORD_SIZE-1:0] external_data0;
	output reg [`WORD_SIZE-1:0] external_data1;
	output reg [`WORD_SIZE-1:0] external_data2;
	output reg [`WORD_SIZE-1:0] external_data3;

	reg [`WORD_SIZE-1:0] stored_external_data [11:0];
	reg [`WORD_SIZE-1:0] count;

	initial begin
		start_interrupt <= 0;
		count <= 16'h0000;
		external_data0 <= 16'b000;
		external_data1 <= 16'b000;
		external_data2 <= 16'b000;
		external_data3 <= 16'b000;

		stored_external_data[0] <= 16'hDEAD;
		stored_external_data[1] <= 16'hBEEF;
		stored_external_data[2] <= 16'hC0DE;
		stored_external_data[3] <= 16'hBABE;
		stored_external_data[4] <= 16'hFEED;
		stored_external_data[5] <= 16'hCAFE;
		stored_external_data[6] <= 16'hBAAD;
		stored_external_data[7] <= 16'h2BAD;
		stored_external_data[8] <= 16'hC001;
		stored_external_data[9] <= 16'hB002;
		stored_external_data[10] <= 16'hD00D;
		stored_external_data[11] <= 16'hB00C;
	end

	always@(*)begin
		if(BG == 1) begin
			external_data0 <= stored_external_data[offset+16'b11];
			external_data1 <= stored_external_data[offset+16'b10];
			external_data2 <= stored_external_data[offset+16'b01];
			external_data3 <= stored_external_data[offset+16'b00];
		end
		else begin
			external_data0 <= 16'b000;
			external_data1 <= 16'b000;
			external_data2 <= 16'b000;
			external_data3 <= 16'b000;
		end
	end
	/* give one time interrupt after xxx cycles */
	always@(posedge clk) begin
		
		count <= count + 1;

		if(count == 500) begin
			$display("*****************************");
			$display("**********DMA start**********");
			$display("*****************************");
			start_interrupt <= 1;					
		end

		if(count == 501) begin
			start_interrupt <= 0;
		end
	end
endmodule