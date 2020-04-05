// Title         : vending_machine.v
// Author      : Jae-Eon Jo (Jojaeeon@postech.ac.kr) 
//					   Dongup Kwon (nankdu7@postech.ac.kr) (2015.03.30)
/*
`define kTotalBits 31
  
`define kItemBits 8
`define kNumItems 4

`define kCoinBits 8
`define kNumCoins 3

`define kWaitTime 10
*/

`timescale 100ps / 100ps

`include "vending_machine_def.v"

module vending_machine (

	clk,							// Clock signal
	reset_n,						// Reset signal (active-low)
	
	i_input_coin,				// coin is inserted.
	i_select_item,				// item is selected.
	i_trigger_return,			// change-return is triggered 
	
	o_available_item,			// Sign of the item availability
	o_output_item,			// Sign of the item withdrawal
	o_return_coin				// Sign of the coin return
);

	// Ports Declaration
	// Do not modify the module interface
	input clk;
	input reset_n;
	
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0] i_select_item;
	input i_trigger_return;
		
	output [`kNumItems-1:0] o_available_item;
	output [`kNumItems-1:0] o_output_item;
	output [`kNumCoins-1:0] o_return_coin;
 
	// Normally, every output is register,
	//   so that it can provide stable value to the outside.
	reg [`kNumItems-1:0] o_available_item;
	reg [`kNumItems-1:0] o_output_item;
	reg [`kNumCoins-1:0] o_return_coin;
	
	// Net constant values (prefix kk & CamelCase)
	// Please refer the wikepedia webpate to know the CamelCase practive of writing.
	// http://en.wikipedia.org/wiki/CamelCase
	// Do not modify the values.
	wire [31:0] kkItemPrice [`kNumItems-1:0];	// Price of each item
	wire [31:0] kkCoinValue [`kNumCoins-1:0];	// Value of each coin
	assign kkItemPrice[0] = 400;
	assign kkItemPrice[1] = 500;
	assign kkItemPrice[2] = 1000;
	assign kkItemPrice[3] = 2000;
	assign kkCoinValue[0] = 100;
	assign kkCoinValue[1] = 500;
	assign kkCoinValue[2] = 1000;


	// NOTE: integer will never be used other than special usages.
	// Only used for loop iteration.
	// You may add more integer variables for loop iteration.
	integer i, j, k;

	// Internal states. You may add your own net & reg variables.
	reg [`kTotalBits-1:0] current_total;
	
	// Next internal states. You may add your own net and reg variables.
	reg [`kTotalBits-1:0] current_total_nxt;
	
	// Variables. You may add more your own registers.
	reg [`kTotalBits-1:0] input_total, output_total, return_total;
	reg [31:0] wait_time;
	reg [7:0] total_money;
	reg [7:0] total_money_next;

	// initiate values
	initial begin
		// TODO: initiate values
	o_available_item = 0;
	o_output_item = 0;
	o_return_coin = 0;
	current_total = 0;
	current_total_nxt = 0;
	input_total = 0;
	output_total = 0;
	return_total = 0;

	total_money = 0;
	total_money_next = 0;
	wait_time = `kWaitTime;

	end

	
	// Combinational logic for the next states
	always @(posedge clk or posedge reset_n) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		
		// Calculate the next current_total state.
		
		// You may add more next states.
		if(i_input_coin == 'b001) begin
			total_money_next <= total_money + 1;
			wait_time = `kWaitTime;
		end
		else if (i_input_coin == 'b010) begin
			total_money_next <= total_money + 5;
			wait_time = `kWaitTime;
		end
		else if (i_input_coin == 'b100) begin
			total_money_next <= total_money + 10;	
			wait_time = `kWaitTime;
		end
			
	end
	
	
	
	// Combinational logic for the outputs
	always @(*) begin
		// TODO: o_available_item
		if(total_money < 4) 
			o_available_item = 4'b0000;
		if(total_money >= 4)
			o_available_item = 4'b0001;
		if(total_money_next >= 5)
			o_available_item = 4'b0011;
		if(total_money >= 10)
			o_available_item = 4'b0111;
		if(total_money >= 20)
			o_available_item = 4'b1111;
	

		// TODO: o_output_item
		o_output_item = i_select_item & o_available_item;
		#50

		if(o_output_item == 4'b0001) begin
			//$display("%d", total_money);
			//$display("%d", wait_time);
			total_money_next <= total_money - 4;
			wait_time = `kWaitTime;
		end
		
		
		if(o_output_item == 4'b0010) begin
			total_money_next <= total_money - 5;
			wait_time = `kWaitTime;
		end

		
		if(o_output_item == 4'b0100) begin
			total_money_next <= total_money - 10;
			wait_time = `kWaitTime;
		end

		
		if(o_output_item == 4'b1000) begin
			total_money_next <= total_money - 20;
			wait_time = `kWaitTime;
		end

		
		// TODO: o_return_coin
		if(wait_time <= 0) begin
		//$display("%d", wait_time);
			if(total_money != 0) begin
			//$display("%d", total_money);
				o_return_coin = 3'b001;
				total_money_next <= total_money - 1;
				//wait_time <= wait_time + 1;
			end
			else wait_time = `kWaitTime;

		end

		if(i_trigger_return == 1) begin
		//$display("%d", wait_time);
			if(total_money != 0) begin
			//$display("%d", total_money);
				o_return_coin = 3'b001;
				total_money_next <= total_money - 1;			
			end
			else wait_time = `kWaitTime;
		
		end

	end

 
	
	
	// Sequential circuit to reset or update the states
	always @(posedge clk) begin
		if (!reset_n) begin
			// TODO: reset all states.
			total_money = 0;
			total_money_next = 0;
			o_available_item = 4'b0000;
			o_output_item = 0;
			wait_time = `kWaitTime;
		end
		else begin
			wait_time = wait_time - 1;
			total_money <= total_money_next;
		end
	end

endmodule