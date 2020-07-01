`timescale 1ns/1ns	

`include "opcodes.v"


module DMA_controller (clk,start_require, dma_address_cpu,  dma_address_out, BG, BR, offset, end_interrupt, dma_ready, cpu_data);
	
	/* input */
	input clk;
	wire clk;
	input start_require;
	wire start_require;
	input BG;
	wire BG;
	input [`WORD_SIZE-1:0] dma_address_cpu;
	wire [`WORD_SIZE-1:0] dma_address_cpu;
	input dma_ready;
    wire dma_ready;
	input [`WORD_SIZE-1:0] cpu_data;
	wire [`WORD_SIZE-1:0] cpu_data;

	/* output */
	output BR;
	reg BR;
	output end_interrupt;
	reg end_interrupt;
	output [`WORD_SIZE-1:0] dma_address_out;
	reg [`WORD_SIZE-1:0] dma_address_out;
	output [`WORD_SIZE-1:0] offset;
	reg [`WORD_SIZE-1:0] offset;
	reg [`WORD_SIZE-1:0] dma_num;
	
	initial begin
		end_interrupt = 1'b0;
		offset = 16'b0;
		BR = 1'b0;
	end

	always @(posedge clk) begin

		if (start_require) begin
			BR <= 1'b1;
			dma_address_out <= dma_address_cpu;
		end

		if(BG && dma_ready) begin
			if(offset != cpu_data) offset = offset + 16'd4;
			else begin
				if(end_interrupt == 0) begin
					$display("********************");
					$display("*******END DMA******");
					$display("********************");
					end_interrupt <=1'b1;
					BR <= 1'b0;
				end
			end
		end

		if(end_interrupt) end_interrupt <=1'b0;

	end

endmodule