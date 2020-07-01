`timescale 1ns/1ns
`include "opcodes.v"
`define PERIOD1 100
`define MEMORY_SIZE 256   //   size of memory is 2^8 words (reduced size)
`define WORD_SIZE 16   //   instead of 2^16 words to reduce memory
         //   requirements in the Active-HDL simulator 

module Memory(clk, reset_n, readM1, address1, data1, readM2, writeM2, address2, data2, is_ready, BG, BR, dma_address, external_data0, external_data1, external_data2, external_data3, end_interrupt, dma_ready, start_interrupt);
   input clk;
   wire clk;
   input reset_n;
   wire reset_n;
   
   input readM1;
   wire readM1;
   input [`WORD_SIZE-1:0] address1;
   wire [`WORD_SIZE-1:0] address1;
   output data1;
   reg [`WORD_SIZE-1:0] data1;
   
   input readM2;
   wire readM2;
   input writeM2;
   wire writeM2;
   input [`WORD_SIZE-1:0] address2;
   wire [`WORD_SIZE-1:0] address2;
   inout data2;
   wire [`WORD_SIZE-1:0] data2;
   
   reg [`WORD_SIZE-1:0] memory [0:`MEMORY_SIZE-1];
   reg [`WORD_SIZE-1:0] outputData2;

   output is_ready;
   reg is_ready;

   reg[`WORD_SIZE-1:0] timer;

   reg[`WORD_SIZE-1:0] counting;
   reg mem_ready;

   reg [`WORD_SIZE-1:0] access;
   reg [`WORD_SIZE-1:0] hit;

   reg random;
   reg check;
   /* Cache */

      //Address
      /*************************************************************/
      /*        TAG(15:4)                 /   IDX(3:2)   / BO(1:0) */
      /*************************************************************/

      //One line in cache
      /********************************************************************************************************/
      /*   TAG(77:66)  / Valid(65) / Dirty(64) / block3(63:48) / block2(47:32) / block1(31:16) / block0(15:0) */
      /********************************************************************************************************/

   
   reg [`LINE_SIZE-1:0] cache [0:`LINE_NUM-1];
   reg [`LINE_SIZE-1:0] cache_2 [0:`LINE_NUM-1];
   reg [`LINE_NUM-1:0] LRU;//if LRU value is 0, least recently used than that of line in cache_2
   wire I_hit;
   wire D_hit;

	input BG;
	wire BG;
	input BR;
	wire BR;
	input end_interrupt;
	wire end_interrupt;
   input start_interrupt;
   wire start_interrupt;

   input wire [`WORD_SIZE-1:0] external_data0;
   input wire [`WORD_SIZE-1:0] external_data1;
   input wire [`WORD_SIZE-1:0] external_data2;
   input wire [`WORD_SIZE-1:0] external_data3;

   input [`WORD_SIZE-1:0] dma_address;
	wire [`WORD_SIZE-1:0] dma_address;
   reg[`WORD_SIZE-1:0] load_time;
   reg[`WORD_SIZE-1:0] load_time_write_through;

   output dma_ready;
   reg dma_ready;
   reg[`WORD_SIZE-1:0] dma_timer;

   reg miss_check;

   assign data2 = readM2 ? outputData2:`WORD_SIZE'bz;
   assign I_hit = ((address1[15:4] == cache[address1[3:2]][77:66]) && cache[address1[3:2]][`VALID]) || ((address1[15:4] == cache_2[address1[3:2]][77:66]) && cache_2[address1[3:2]][`VALID]);
   assign D_hit = ((address2[15:4] == cache[address2[3:2]][77:66]) && cache[address2[3:2]][`VALID]) || ((address2[15:4] == cache_2[address2[3:2]][77:66]) && cache_2[address2[3:2]][`VALID]);

   always@(posedge clk) begin
      if(!reset_n)
         begin
            is_ready <= 1'b0;

            load_time <= 16'b100;
            load_time_write_through <= 16'b100;

            miss_check <= 1'b0;
            dma_ready <= 1'b1;
            dma_timer <= 16'b100;
            counting <= 16'b000;

            mem_ready <= 1'b0;
            timer <= 16'b100;
            access <= 0;
            hit <= 0;

            check <= 1'b0;
            LRU <= 4'b0000;
            cache[0] = 78'b0;
            cache[1] = 78'b0;
            cache[2] = 78'b0;
            cache[3] = 78'b0;

            cache_2[0] = 78'b0;
            cache_2[1] = 78'b0;
            cache_2[2] = 78'b0;
            cache_2[3] = 78'b0;
            

            memory[16'h0] <= 16'h9023;
            memory[16'h1] <= 16'h1;
            memory[16'h2] <= 16'hffff;
            memory[16'h3] <= 16'h0;

            memory[16'h4] <= 16'h0;
            memory[16'h5] <= 16'h0;
            memory[16'h6] <= 16'h0;
            memory[16'h7] <= 16'h0;
            memory[16'h8] <= 16'h0;
            memory[16'h9] <= 16'h0;
            memory[16'ha] <= 16'h0;
            memory[16'hb] <= 16'h0;
            memory[16'hc] <= 16'h0;
            memory[16'hd] <= 16'h0;
            memory[16'he] <= 16'h0;
            memory[16'hf] <= 16'h0;
            memory[16'h10] <= 16'h0;
            memory[16'h11] <= 16'h0;
            memory[16'h12] <= 16'h0;
            memory[16'h13] <= 16'h0;
            memory[16'h14] <= 16'h0;
            memory[16'h15] <= 16'h0;
            memory[16'h16] <= 16'h0;
            memory[16'h17] <= 16'h0;
            memory[16'h18] <= 16'h0;
            memory[16'h19] <= 16'h0;
            memory[16'h1a] <= 16'h0;
            memory[16'h1b] <= 16'h0;
            memory[16'h1c] <= 16'h0;
            memory[16'h1d] <= 16'h0;
            memory[16'h1e] <= 16'h0;
            memory[16'h1f] <= 16'h0;
            
            memory[16'h20] <= 16'h0;
            memory[16'h21] <= 16'h0;
            memory[16'h22] <= 16'h0;
            memory[16'h23] <= 16'h6000;

            memory[16'h24] <= 16'hf01c;
            memory[16'h25] <= 16'h6100;
            memory[16'h26] <= 16'hf41c;
            memory[16'h27] <= 16'h6200;
            memory[16'h28] <= 16'hf81c;
            memory[16'h29] <= 16'h6300;
            memory[16'h2a] <= 16'hfc1c;
            memory[16'h2b] <= 16'h4401;
            memory[16'h2c] <= 16'hf01c;
            memory[16'h2d] <= 16'h4001;
            memory[16'h2e] <= 16'hf01c;
            memory[16'h2f] <= 16'h5901;

            memory[16'h30] <= 16'hf41c;
            memory[16'h31] <= 16'h5502;
            memory[16'h32] <= 16'hf41c;
            memory[16'h33] <= 16'h5503;

            memory[16'h34] <= 16'hf41c;
            memory[16'h35] <= 16'hf2c0;
            memory[16'h36] <= 16'hfc1c;
            memory[16'h37] <= 16'hf6c0;
            memory[16'h38] <= 16'hfc1c;
            memory[16'h39] <= 16'hf1c0;
            memory[16'h3a] <= 16'hfc1c;
            memory[16'h3b] <= 16'hf2c1;
            memory[16'h3c] <= 16'hfc1c;
            memory[16'h3d] <= 16'hf8c1;
            memory[16'h3e] <= 16'hfc1c;
            memory[16'h3f] <= 16'hf6c1;
            memory[16'h40] <= 16'hfc1c;
            memory[16'h41] <= 16'hf9c1;
            memory[16'h42] <= 16'hfc1c;
            memory[16'h43] <= 16'hf1c1;
            memory[16'h44] <= 16'hfc1c;
            memory[16'h45] <= 16'hf4c1;
            memory[16'h46] <= 16'hfc1c;
            memory[16'h47] <= 16'hf2c2;
            memory[16'h48] <= 16'hfc1c;
            memory[16'h49] <= 16'hf6c2;
            memory[16'h4a] <= 16'hfc1c;
            memory[16'h4b] <= 16'hf1c2;
            memory[16'h4c] <= 16'hfc1c;
            memory[16'h4d] <= 16'hf2c3;
            memory[16'h4e] <= 16'hfc1c;
            memory[16'h4f] <= 16'hf6c3;
            memory[16'h50] <= 16'hfc1c;
            memory[16'h51] <= 16'hf1c3;
            memory[16'h52] <= 16'hfc1c;
            memory[16'h53] <= 16'hf0c4;
            memory[16'h54] <= 16'hfc1c;
            memory[16'h55] <= 16'hf4c4;
            memory[16'h56] <= 16'hfc1c;
            memory[16'h57] <= 16'hf8c4;
            memory[16'h58] <= 16'hfc1c;
            memory[16'h59] <= 16'hf0c5;
            memory[16'h5a] <= 16'hfc1c;
            memory[16'h5b] <= 16'hf4c5;
            memory[16'h5c] <= 16'hfc1c;
            memory[16'h5d] <= 16'hf8c5;
            memory[16'h5e] <= 16'hfc1c;
            memory[16'h5f] <= 16'hf0c6;
            memory[16'h60] <= 16'hfc1c;
            memory[16'h61] <= 16'hf4c6;
            memory[16'h62] <= 16'hfc1c;
            memory[16'h63] <= 16'hf8c6;
            memory[16'h64] <= 16'hfc1c;
            memory[16'h65] <= 16'hf0c7;
            memory[16'h66] <= 16'hfc1c;
            memory[16'h67] <= 16'hf4c7;
            memory[16'h68] <= 16'hfc1c;
            memory[16'h69] <= 16'hf8c7;
            memory[16'h6a] <= 16'hfc1c;
            memory[16'h6b] <= 16'h7801;
            memory[16'h6c] <= 16'hf01c;
            memory[16'h6d] <= 16'h7902;
            memory[16'h6e] <= 16'hf41c;
            memory[16'h6f] <= 16'h8901;
            memory[16'h70] <= 16'h8802;
            memory[16'h71] <= 16'h7801;
            memory[16'h72] <= 16'hf01c;
            memory[16'h73] <= 16'h7902;
            memory[16'h74] <= 16'hf41c;
            memory[16'h75] <= 16'h9076;
            memory[16'h76] <= 16'hf01c;
            memory[16'h77] <= 16'h9079;
            memory[16'h78] <= 16'hf01d;
            memory[16'h79] <= 16'hf41c;
            memory[16'h7a] <= 16'hb01;
            memory[16'h7b] <= 16'h907d;
            memory[16'h7c] <= 16'hf01d;
            memory[16'h7d] <= 16'hf01c;
            memory[16'h7e] <= 16'h601;
            memory[16'h7f] <= 16'hf01d;
            memory[16'h80] <= 16'hf41c;
            memory[16'h81] <= 16'h1601;
            memory[16'h82] <= 16'h9084;
            memory[16'h83] <= 16'hf01d;
            memory[16'h84] <= 16'hf01c;
            memory[16'h85] <= 16'h1b01;
            memory[16'h86] <= 16'hf01d;
            memory[16'h87] <= 16'hf41c;
            memory[16'h88] <= 16'h2001;
            memory[16'h89] <= 16'h908b;
            memory[16'h8a] <= 16'hf01d;
            memory[16'h8b] <= 16'hf01c;
            memory[16'h8c] <= 16'h2401;
            memory[16'h8d] <= 16'hf01d;
            memory[16'h8e] <= 16'hf41c;
            memory[16'h8f] <= 16'h2801;
            memory[16'h90] <= 16'h9092;
            memory[16'h91] <= 16'hf01d;
            memory[16'h92] <= 16'hf01c;
            memory[16'h93] <= 16'h3001;
            memory[16'h94] <= 16'hf01d;
            memory[16'h95] <= 16'hf41c;
            memory[16'h96] <= 16'h3401;
            memory[16'h97] <= 16'h9099;
            memory[16'h98] <= 16'hf01d;
            memory[16'h99] <= 16'hf01c;
            memory[16'h9a] <= 16'h3801;
            memory[16'h9b] <= 16'h909d;
            memory[16'h9c] <= 16'hf01d;
            memory[16'h9d] <= 16'hf41c;
            memory[16'h9e] <= 16'ha0af;
            memory[16'h9f] <= 16'hf01c;
            memory[16'ha0] <= 16'ha0ae;
            memory[16'ha1] <= 16'hf01d;
            memory[16'ha2] <= 16'hf41c;
            memory[16'ha3] <= 16'h6300;
            memory[16'ha4] <= 16'h5f03;
            memory[16'ha5] <= 16'h6000;
            memory[16'ha6] <= 16'h4005;
            memory[16'ha7] <= 16'ha0b2;
            memory[16'ha8] <= 16'hf01c;
            memory[16'ha9] <= 16'h90b1;
            memory[16'haa] <= 16'h4900;
            memory[16'hab] <= 16'hf41a;
            memory[16'hac] <= 16'hf01c;
            memory[16'had] <= 16'hf01d;
            memory[16'hae] <= 16'h4a01;
            memory[16'haf] <= 16'hf819;
            memory[16'hb0] <= 16'hf01d;
            memory[16'hb1] <= 16'ha0aa;
            memory[16'hb2] <= 16'h41ff;
            memory[16'hb3] <= 16'h2404;
            memory[16'hb4] <= 16'h6000;
            memory[16'hb5] <= 16'h5001;
            memory[16'hb6] <= 16'hf819;
            memory[16'hb7] <= 16'hf01d;
            memory[16'hb8] <= 16'h8e00;
            memory[16'hb9] <= 16'h8c01;
            memory[16'hba] <= 16'h4f02;
            memory[16'hbb] <= 16'h40fe;
            memory[16'hbc] <= 16'ha0b2;
            memory[16'hbd] <= 16'h7dff;
            memory[16'hbe] <= 16'h8cff;
            memory[16'hbf] <= 16'h44ff;
            memory[16'hc0] <= 16'ha0b2;
            memory[16'hc1] <= 16'h7dff;
            memory[16'hc2] <= 16'h7efe;
            memory[16'hc3] <= 16'hf100;
            memory[16'hc4] <= 16'h4ffe;
            memory[16'hc5] <= 16'hf819;
            memory[16'hc6] <= 16'hf01d;
         end /* if end */
      
      else begin
         /* this is for extra credit 2 */
			if(dma_address[15:4] == cache[dma_address[3:2]][77:66] && BG) begin//invalidate cache line sync-out because of device
				cache[dma_address[3:2]][`VALID] <= 1'b0;
         end
         if(dma_address[15:4] == cache_2[dma_address[3:2]][77:66] && BG) begin//invalidate cache line sync-out because of device
				cache_2[dma_address[3:2]][`VALID] <= 1'b0;
         end
         /* this is for extra credit 2 */

         $display("Access: %d, Hit: %d", access, hit);

         //cache hit
         if(I_hit && D_hit || I_hit && !(readM2 || writeM2)) begin
            
            if(readM1) begin //reading instruction from memory
               if(writeM2 && address1 == address2) begin
                  data1 <= data2;
               end
               else begin

                  if(address1[15:4] == cache[address1[3:2]][77:66]) begin//if hit in set 1
                 LRU[address1[3:2]] <= 1;
                     case(address1[1:0])
                        2'b00 : data1 <= cache[address1[3:2]][15:0];
                        2'b01 : data1 <= cache[address1[3:2]][31:16];
                        2'b10 : data1 <= cache[address1[3:2]][47:32];
                        2'b11 : data1 <= cache[address1[3:2]][63:48];
                     endcase
                  end
                  else if(address1[15:4] == cache_2[address1[3:2]][77:66]) begin//if hit in set 2
                 LRU[address1[3:2]] <= 0;
                     case(address1[1:0])
                        2'b00 : data1 <= cache_2[address1[3:2]][15:0];
                        2'b01 : data1 <= cache_2[address1[3:2]][31:16];
                        2'b10 : data1 <= cache_2[address1[3:2]][47:32];
                        2'b11 : data1 <= cache_2[address1[3:2]][63:48];
                     endcase
                  end
               end
            end
               
            if(readM2) begin //reading data from memory
               //outputData2 <= memory[address2];

               if(address2[15:4] == cache[address2[3:2]][77:66]) begin//if hit in set 1
               LRU[address2[3:2]] <= 1;
                  case(address2[1:0])
                     2'b00 : outputData2 <= cache[address2[3:2]][15:0];
                     2'b01 : outputData2 <= cache[address2[3:2]][31:16];
                     2'b10 : outputData2 <= cache[address2[3:2]][47:32];
                     2'b11 : outputData2 <= cache[address2[3:2]][63:48];
                  endcase
               end
               else if (address2[15:4] == cache_2[address2[3:2]][77:66]) begin//if hit in set 2
               LRU[address2[3:2]] <= 0;
                  case(address2[1:0])
                     2'b00 : outputData2 <= cache_2[address2[3:2]][15:0];
                     2'b01 : outputData2 <= cache_2[address2[3:2]][31:16];
                     2'b10 : outputData2 <= cache_2[address2[3:2]][47:32];
                     2'b11 : outputData2 <= cache_2[address2[3:2]][63:48];
                  endcase   
               end
               
            end

            if(writeM2) begin // CPU wants to write data to memory
               memory[address2] <= data2;

            if(is_ready) begin
               if(address2[15:4] == cache[address2[3:2]][77:66]) begin//if hit in set 1
              LRU[address2[3:2]] <= 1;
                  case(address2[1:0])
                     2'b00 : cache[address2[3:2]][15:0] <= data2;
                     2'b01 : cache[address2[3:2]][31:16] <= data2;
                     2'b10 : cache[address2[3:2]][47:32] <= data2;
                     2'b11 : cache[address2[3:2]][63:48] <= data2;
                  endcase
               end

               else if (address2[15:4] == cache_2[address2[3:2]][77:66]) begin//if hit in set 2
                  LRU[address2[3:2]] <= 0;
                  case(address2[1:0])
                     2'b00 : cache_2[address2[3:2]][15:0] <= data2;
                     2'b01 : cache_2[address2[3:2]][31:16] <= data2;
                     2'b10 : cache_2[address2[3:2]][47:32] <= data2;
                     2'b11 : cache_2[address2[3:2]][63:48] <= data2;
                  endcase
               end
                  is_ready <= 1'b0;
                  load_time_write_through <= 16'b100;
            end

               else if(load_time_write_through != 16'b0) begin
                  load_time_write_through <= load_time_write_through-16'b1;
               end

               else begin 
                  is_ready <= 1;
                  memory[address2] <= data2;
               end
            end

            access <= access + 1;
            hit <= hit + 1;
         end
         
         //memory access

         /* miss & DMA is off */
			else if((readM1 || readM2 || writeM2) && (!BG)) begin
            if(is_ready) begin

               if(readM1) begin
                  if(writeM2 & address1==address2) begin
                     data1 <= data2;
                  end
                  else begin
                     data1 <= memory[address1];
                  end
               end

               if(readM2) begin 
                  outputData2 <= memory[address2];
               end

               if(writeM2) begin
                  memory[address2] <= data2;
               end

               is_ready <= 1'b0;
               timer <= 16'b100;
               access <= access + 1;
            end

            else if(timer != 16'b0) begin
               timer <= timer-16'b1;
            end

            else begin
            if (I_hit == 0) begin
               if(cache[address1[3:2]][`VALID] == 0) begin
                  cache[address1[3:2]] <= {address1[15:4],1'b1,1'b0,{memory[{address1[`WORD_SIZE-1:2],2'b11}],memory[{address1[`WORD_SIZE-1:2],2'b10}],
                  memory[{address1[`WORD_SIZE-1:2],2'b01}],memory[{address1[`WORD_SIZE-1:2],2'b00}]}};
               end

               else if (cache_2[address1[3:2]][`VALID] == 0) begin
                  cache_2[address1[3:2]] <= {address1[15:4],1'b1,1'b0,{memory[{address1[`WORD_SIZE-1:2],2'b11}],memory[{address1[`WORD_SIZE-1:2],2'b10}],
                  memory[{address1[`WORD_SIZE-1:2],2'b01}],memory[{address1[`WORD_SIZE-1:2],2'b00}]}};
               end

               else begin            
                  
                  if(LRU[address1[3:2]] == 0) begin
                     cache[address1[3:2]] <= {address1[15:4],1'b1,1'b0,{memory[{address1[`WORD_SIZE-1:2],2'b11}],memory[{address1[`WORD_SIZE-1:2],2'b10}],
                     memory[{address1[`WORD_SIZE-1:2],2'b01}],memory[{address1[`WORD_SIZE-1:2],2'b00}]}};
                  end

                  else begin
                     cache_2[address1[3:2]] <= {address1[15:4],1'b1,1'b0,{memory[{address1[`WORD_SIZE-1:2],2'b11}],memory[{address1[`WORD_SIZE-1:2],2'b10}],
                     memory[{address1[`WORD_SIZE-1:2],2'b01}],memory[{address1[`WORD_SIZE-1:2],2'b00}]}};
                  end

               end
            end

               if(address1[3:2] != address2[3:2]) begin

               if (I_hit == 1 && D_hit == 0) begin
                  if(cache[address2[3:2]][`VALID] == 0) begin
                     cache[address2[3:2]] <= {address2[15:4],1'b1,1'b0,{memory[{address2[`WORD_SIZE-1:2],2'b11}],memory[{address2[`WORD_SIZE-1:2],2'b10}],
                     memory[{address2[`WORD_SIZE-1:2],2'b01}],memory[{address2[`WORD_SIZE-1:2],2'b00}]}};
                  end

                  else if (cache_2[address2[3:2]][`VALID] == 0) begin
                     cache_2[address2[3:2]] <= {address2[15:4],1'b1,1'b0,{memory[{address2[`WORD_SIZE-1:2],2'b11}],memory[{address2[`WORD_SIZE-1:2],2'b10}],
                     memory[{address2[`WORD_SIZE-1:2],2'b01}],memory[{address2[`WORD_SIZE-1:2],2'b00}]}};
                  end

                  else begin
                     if(LRU[address2[3:2]] == 0) begin
                        cache[address2[3:2]] <= {address2[15:4],1'b1,1'b0,{memory[{address2[`WORD_SIZE-1:2],2'b11}],memory[{address2[`WORD_SIZE-1:2],2'b10}],
                        memory[{address2[`WORD_SIZE-1:2],2'b01}],memory[{address2[`WORD_SIZE-1:2],2'b00}]}};
                     end

                     else begin
                        cache_2[address2[3:2]] <= {address2[15:4],1'b1,1'b0,{memory[{address2[`WORD_SIZE-1:2],2'b11}],memory[{address2[`WORD_SIZE-1:2],2'b10}],
                        memory[{address2[`WORD_SIZE-1:2],2'b01}],memory[{address2[`WORD_SIZE-1:2],2'b00}]}};
                     end
                  end
               end
               end
               is_ready <= 1'b1;
            end
         end
         else begin
$display("miss & I/O!!");
                  is_ready <= 1'b0;
                  miss_check <= 1'b1;
            end


         if (BG && BR) begin /* write memory from external_device */
$display("dma_address: %d, dma_ready: %d, I_hit: %d, D_hit: %d, counting: %d", dma_address, dma_ready, I_hit, D_hit, counting);

            if(dma_ready) begin
               memory[dma_address+16'b0] <= external_data0;
               memory[dma_address+16'b1] <= external_data1;
               memory[dma_address+16'b10] <= external_data2;
               memory[dma_address+16'b11] <= external_data3;
               dma_ready <= 1'b0;
               dma_timer <= 16'b100;
               counting <= counting + 1;
            end
            else if(dma_timer != 16'b0) begin
               dma_timer <= dma_timer -1;
            end
            else begin
                  dma_ready <= 1'b1;
            end
         end

      end /* else end */

      /* if finished, then display the result */
      if(end_interrupt) begin
			$display("memory[16'h10]:%h",memory[16'h10]);
            $display("memory[16'h11]:%h",memory[16'h11]);
            $display("memory[16'h12]:%h",memory[16'h12]);
            $display("memory[16'h13]:%h",memory[16'h13]);
            $display("memory[16'h14]:%h",memory[16'h14]);
            $display("memory[16'h15]:%h",memory[16'h15]);
            $display("memory[16'h16]:%h",memory[16'h16]);
            $display("memory[16'h17]:%h",memory[16'h17]);
            $display("memory[16'h18]:%h",memory[16'h18]);
            $display("memory[16'h19]:%h",memory[16'h19]);
            $display("memory[16'h1a]:%h",memory[16'h1a]);
            $display("memory[16'h1b]:%h",memory[16'h1b]);
            /* if there was miss & I/O, update is_ready to 1 */
            if(miss_check) begin
               is_ready <= 1'b1;
            end

		end
   end /* always end */
endmodule