
`timescale 1ns/1ns
`include "opcodes.v"
`define PERIOD1 100
`define MEMORY_SIZE 256	//	size of memory is 2^8 words (reduced size)

			//	requirements in the Active-HDL simulator 
module Cache(clk, reset_n, readM1, address1, data1, readM2, writeM2, address2, data2,
 finish,access_num,hit_num, readM1_mem,readM2_mem, writeM2_mem,data1_mem,write_data, data2_mem, evict1,evict2, finish_mem);
	input clk;
	wire clk;
	input reset_n;
	wire reset_n;
	
	//1 is for instructions
	input readM1;
	wire readM1;
	input [`WORD_SIZE-1:0] address1;
	wire [`WORD_SIZE-1:0] address1;
	output [`WORD_SIZE-1:0] data1;
	reg [`WORD_SIZE-1:0] data1;
	// 2 is for Data
	input readM2;
	wire readM2;
	input writeM2;
	wire writeM2;
	input [`WORD_SIZE-1:0] address2;
	wire [`WORD_SIZE-1:0] address2;
	inout [`WORD_SIZE-1:0] data2;
	wire [`WORD_SIZE-1:0] data2;
	output finish; // when finish is 0, cache is being written; otherwise cache can be accessed
	reg finish;

	output [`WORD_SIZE-1:0] access_num;//for counting # of memory access and cache hit
	reg [`WORD_SIZE-1:0] access_num;
	output [`WORD_SIZE-1:0] hit_num;
	reg [`WORD_SIZE-1:0] hit_num;

	output [`WORD_SIZE-1:0] write_data;
	reg [`WORD_SIZE-1:0] write_data;
	input [`WORD_SIZE*`BLOCK_SIZE-1:0] data1_mem;
	wire [`WORD_SIZE*`BLOCK_SIZE-1:0] data1_mem;
	input [`WORD_SIZE*`BLOCK_SIZE-1:0] data2_mem;
	wire [`WORD_SIZE*`BLOCK_SIZE-1:0] data2_mem;
	
	input finish_mem;
	wire finish_mem;// signal from memory after reading
	
	reg [`LINE_SIZE-1:0] cache [0:`BLOCK_NUM-1];
	reg [`WORD_SIZE-1:0] outputData2;
	output [`LINE_SIZE-1:0] evict1;
	reg [`LINE_SIZE-1:0] evict1;
	output [`LINE_SIZE-1:0] evict2;
	reg [`LINE_SIZE-1:0] evict2;
	output readM1_mem;
	reg readM1_mem;
	output readM2_mem;
	reg readM2_mem;
	output writeM2_mem;
	reg writeM2_mem;
	wire I_hit;
	wire D_hit;
	
	assign data2 = readM2? outputData2:`WORD_SIZE'bz;
	assign I_hit = (address1[15:5] == cache[address1[4:2]][76:66]) && cache[address1[4:2]][`VALID];
	assign D_hit = (address2[15:5] == cache[address2[4:2]][76:66]) && cache[address2[4:2]][`VALID];

	

	
	always@(posedge clk)
		if(!reset_n)
			begin
				access_num <= 16'b0;
				hit_num <=16'b0;
				finish <= 1'b1;
				cache[0] = 77'b0;
				cache[1] = 77'b0;
				cache[2] = 77'b0;
				cache[3] = 77'b0;
				cache[4] = 77'b0;
				cache[5] = 77'b0;
				cache[6] = 77'b0;
				cache[7] = 77'b0;
			end
		else
			begin
				if(I_hit && (D_hit || !(readM2 || writeM2))) begin//cache hit
					
					hit_num <= hit_num +1;
					access_num <= access_num + 1;
					
					if(readM1) begin// CPU requires instruction from memory
						if(writeM2 && address1==address2) begin// just for in case when the pc is same as the address that CPU writes a value to
							data1 <= data2;
						end
						else begin
							case(address1[1:0])//find the proper cache line and return the data1(=instruction)
								2'b00 : data1 <= cache[address1[4:2]][15:0];
								2'b01 : data1 <= cache[address1[4:2]][31:16];
								2'b10 : data1 <= cache[address1[4:2]][47:32];
								2'b11 : data1 <= cache[address1[4:2]][63:48];
							endcase
						end
					end

					if(readM2) begin// CPU requires data from memory
						case(address2[1:0])//find the proper cache line and return the data2(=memory)
							2'b00 : outputData2 <= cache[address2[4:2]][15:0];
							2'b01 : outputData2 <= cache[address2[4:2]][31:16];
							2'b10 : outputData2 <= cache[address2[4:2]][47:32];
							2'b11 : outputData2 <= cache[address2[4:2]][63:48];
						endcase
					end
					
					if(writeM2) begin// CPU wants data to memory
						case(address2[1:0])
							2'b00 : cache[address2[4:2]][15:0] <= data2;
							2'b01 : cache[address2[4:2]][31:16] <= data2;
							2'b10 : cache[address2[4:2]][47:32] <= data2;
							2'b11 : cache[address2[4:2]][63:48] <= data2;
						endcase
						cache[address2[4:2]][`DIRTY] =1'b1;//dirty bit for write back
					end
					finish <= 1'b1;
				end
				else if(finish) begin//cache miss(evict and memory call)
					access_num <= access_num + 1;//need to access memory
					evict1 <= cache[address1[4:2]];
					evict2 <= cache[address2[4:2]];
					write_data <= data2;
					readM1_mem <= readM1;
					readM2_mem <= readM2;
					writeM2_mem <= writeM2 && !D_hit;//in case write && address is not in the cache
					
					if(writeM2 && D_hit) begin//If the address for the data is in the cache
						case(address2[1:0])//update and set dirty bit
							2'b00 : cache[address2[4:2]][15:0] <= data2;
							2'b01 : cache[address2[4:2]][31:16] <= data2;
							2'b10 : cache[address2[4:2]][47:32] <= data2;
							2'b11 : cache[address2[4:2]][63:48] <= data2;
						endcase
						cache[address2[4:2]][`DIRTY] = 1'b1;
					end
					finish <= 1'b0;
				end

				else if(finish_mem) begin//it's set after reading is done in memory
					//update the cache with values from the memory read before
					cache[address1[4:2]] <= {address1[15:5],1'b1,1'b0,data1_mem};
					if(address1[4:2] != address2[4:2]) begin
						cache[address2[4:2]] <= {address2[15:5],1'b1,1'b0,data2_mem};
					end
					//set the signals back
					readM1_mem <= 1'b0;
					readM2_mem <= 1'b0;
					writeM2_mem <= 1'b0;
					finish <= 1'b1;

					//output the data from memory
					if(readM1) begin
						if(writeM2 & address1==address2) begin
							data1 <= write_data;
						end
						else begin
							case(address1[1:0])
								2'b00 : data1 <= data1_mem[15:0];
								2'b01 : data1 <= data1_mem[31:16];
								2'b10 : data1 <= data1_mem[47:32];
								2'b11 : data1 <= data1_mem[63:48];
							endcase
						end
					end
					if(readM2) begin 
						case(address2[1:0])
							2'b00 : outputData2 <= data2_mem[15:0];
							2'b01 : outputData2 <= data2_mem[31:16];
							2'b10 : outputData2 <= data2_mem[47:32];
							2'b11 : outputData2 <= data2_mem[63:48];
						endcase
					end	
				end

																		  
			end
endmodule