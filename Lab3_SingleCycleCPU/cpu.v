`include "opcodes.v"       

module cpu (readM, writeM, address, data, ackOutput, inputReady, reset_n, clk);
	output reg readM; // "read" signal to memory               
	output reg writeM; // "write" signal to memory                            
	output reg [`WORD_SIZE-1:0] address; // target memory address
	inout [`WORD_SIZE-1:0] data; // data for reading or writing (can be used as both input and output) 
	input ackOutput; // signal from memory ("data is written")       
	input inputReady; // signal from memory ("data is ready for reading")                      
	input reset_n; // reset your CPU (registers, PC, etc)                 
	input clk; // clock signal
   
	reg [`WORD_SIZE-1:0] pc;//program counter

	reg [3:0] Op_Code;//operation code
	reg [1:0] rs, rt, rd, wr;//register index
	reg [`WORD_SIZE-1:0] regs[3:0];//register file
	reg [5:0] Func_Code;//function code
	reg [7:0] Immediate;//immediate value
	reg [`WORD_SIZE-1:0] Sign_Extend_Immediate;//sign extension
	reg [11:0] Target_Address;//jump address

	reg [`WORD_SIZE-1:0] A, B;//ALU operand
	wire [`WORD_SIZE-1:0]C;// ALU result
	wire bcond;// ALU branch condition 

	reg load_check; // check if instruction was 'LWD_OP' or not

	reg Register_Write_Condition;//write condition boolean true or false
	reg [`WORD_SIZE-1:0] Write_Back_Register;//write register value

	//If store, put register value of reg[rt] in memory, otherwise read data
	assign data = (writeM == 1) ? regs[rt] : `WORD_SIZE'bz;

	//initailize
	initial begin
		readM <= 0;
		writeM <= 0;
		address <= 0;
		pc <= 0;
		A <= 0;
		B <= 0;
		Register_Write_Condition = 0;
		Op_Code <= 0;
		regs[0] <= 0;
		regs[1] <= 0;
		regs[2] <= 0;
		regs[3] <= 0;
		load_check = 0;
   	end
   
	ALU alu(Op_Code, A, B, Func_Code, C, bcond);
   
	//Read data from memory
	always @(posedge inputReady) begin
		if(load_check == 0)begin //instruction fetch
		Op_Code <= data[`WORD_SIZE-1:12];
		Target_Address <= data[11:0];
		rs <= data[11:10];
		rt <= data[9:8];
		rd <= data[7:6];
		Func_Code <= data[5:0];
		Immediate <= data[7:0];
		readM <= 0;        
		end

		else if(load_check == 1) begin //put memory value in register
         	wr <= rt;
         	Write_Back_Register <= data;
         	readM <= 0;
         	Register_Write_Condition <= 1;
      		end
   	end

   //Write back result 
	always @(negedge inputReady) begin

		if(Op_Code == `ALU_OP && Func_Code <= `FUNC_SHR) begin // R-type
      		Write_Back_Register <= C;
      		Register_Write_Condition <=1;
   		end

   		else if(Op_Code == `ADI_OP || Op_Code == `ORI_OP) begin // I-type
      		Write_Back_Register <= C; 
      		Register_Write_Condition <=1; 
  		end

   		else if(Op_Code == `LHI_OP) begin // L-type
      		Write_Back_Register = Immediate << 8;
      		Register_Write_Condition <=1;
   		end
   
   		else if(Op_Code == `SWD_OP) writeM <=1; // S-type

      		if(bcond == 1) pc <= pc + Sign_Extend_Immediate;// Branch Condition

	end
   

   //Data is written in memory -> set writeM back to 0
   	always @(posedge ackOutput) begin
      		writeM <= 0;
   	end


//Data read from memory -> Carry out instructions according to types.
   	always @(negedge readM) begin

		if(load_check == 0) begin
      			if( Op_Code == `ALU_OP) begin //R-type (RWD WWD none)
         		A = regs[rs];
        		B = regs[rt];
         		wr = rd;
        		pc = pc + 1;
      			end

      			else if ( Op_Code == `JMP_OP) begin //J-type (JAL JPR JRL none)
        		pc = Target_Address;
      			end

      			else begin //I-type
    			pc = pc + 1;
    				if(Immediate[7] == 1) begin//If MSB is 1 (negative value)
				Sign_Extend_Immediate = {8'hff, Immediate}; //concatenate 1111 1111 
    				end
   				else Sign_Extend_Immediate = {8'h00, Immediate};//MSI is 0, concatenate 0000 0000

   			if(Op_Code >= `BNE_OP && Op_Code <= `BLZ_OP) begin //Branch operation, check bcond
     			A = regs[rs];
      			B = regs[rt];
   			end
   
			else if (Op_Code >= `ADI_OP && Op_Code <= `LHI_OP) begin // Immediate type
               		A = regs[rs];
               		B = Sign_Extend_Immediate;
               		Write_Back_Register = C;  
               		wr = rt;
   			end
   			else begin//Store or Load type
      			address = regs[rs] + Sign_Extend_Immediate;//store
      				if(Op_Code == `LWD_OP) begin //load
				readM = 1; 
				load_check = 1;
				end
   			end
		end
end 
/*********************************************************************/
end
//////Type control after instruction fetch

   //Clock 
	always @(posedge clk) begin
		if(!reset_n) begin//If reset
         	readM <= 0;
         	writeM <= 0;
         	address <= 0;
         	pc <= 0;
         	A <= 0;
         	B <= 0;
         	Register_Write_Condition = 0; 
         	Op_Code <= 0;
	 	load_check <=0;
      		end
      		else begin//read current instruction
         	readM <= 1;
         	Register_Write_Condition <= 0;
         	writeM <= 0;
         	address <= pc;
	 	load_check <= 0;
      		end

      		if(Register_Write_Condition) begin//write back register
             	regs[wr] <= Write_Back_Register;
      		end
   	end

endmodule                                                                                            

/****************************************************************/
/*Slightly modified version of the ALU that we built in lab_one   */
/****************************************************************/
/*************************************************************************************************************************/
module ALU(Op_Code, A, B, Func_Code, C, bcond);

	input [3:0] Op_Code;
   	input [5:0] Func_Code;
   	input [`WORD_SIZE-1:0] A; // 16bits A_input
   	input [`WORD_SIZE-1:0] B; // 16bits B_input


   	output reg [`WORD_SIZE-1:0] C; // 16bits C_output
   	output reg bcond;

   	initial begin
      	C = 0;
      	bcond = 0;
   	end      


   	always @(*) begin
      
      		if (Op_Code == 15) begin // R Type
         		case (Func_Code)
            		`FUNC_ADD: C = (A + B);
            		`FUNC_SUB: C = (A - B);
            		`FUNC_AND: C = (A & B);
            		`FUNC_ORR: C = (A | B);
           		`FUNC_NOT: C = ~A;
           		`FUNC_TCP: C = (~A + 1);
            		`FUNC_SHL: C = (A << 1);
           		`FUNC_SHR: C = (A >> 1);
         		endcase
      		end
      		else begin // I Type
        		case (Op_Code)
            		`ADI_OP: C = (A + B);
            		`ORI_OP: C = (A | B);
            		`LHI_OP: C = (A << 8);
            		`LWD_OP: C = (A + B);
         		endcase
      		end
      // Branch Condition Determination
      		case (Op_Code)
         	`BNE_OP: bcond = ((A != B) ? 1 : 0);
        	`BEQ_OP: bcond = ((A == B) ? 1 : 0);
         	`BGZ_OP: bcond = ((A > 0) ? 1 : 0);
         	`BLZ_OP: bcond = ((A < 0) ? 1 : 0);
        	default: bcond = 0;
      		endcase
   		end
endmodule                                       
