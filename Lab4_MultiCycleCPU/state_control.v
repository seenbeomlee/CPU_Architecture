`define INIT 0
`define IF1  1
`define IF2  2
`define IF3  3
`define IF4  4
`define ID   5
`define EX1  6
`define EX2  7
`define MEM1 8
`define MEM2 9
`define MEM3 10
`define MEM4 11
`define WB   12


module state_control(clk, reset_n, JAL, branch, MemRead, MemWrite, readM, writeM, PvsWriteEn, IorD, IRWrite);
    input clk, reset_n, JAL, branch, MemRead, MemWrite;
    output reg writeM;
    output reg readM;
    output reg PvsWriteEn;
    output reg IorD;
    output reg IRWrite;

    reg [4:0] state;
    reg [4:0] next_state;

    initial begin
        readM <= 0;
        writeM <= 0;
        PvsWriteEn <= 1;
        IorD <= 0;
        IRWrite <= 0;
        state <= 0;
        next_state <= 0;
    end

    // state control, reference Lecture6, 9p
    always @(*) begin

   if(state == `INIT) next_state = `IF1; // initial state
   
   else if (state == `IF1) begin // at IF1, set PvsEriteEn = 0 again.
      		PvsWriteEn = 0;
                readM = 1;
                writeM = 0;
                IorD = 0;
                IRWrite = 1;
                next_state = `IF2; // go to next state
   end

   else if (state == `IF4) begin
                IRWrite = 0;
                readM = 0;
                if(JAL)begin
                    next_state = `EX1; // if JAl go to Ex1 state (skip ID)
                end
                else begin
                    next_state = `ID; // go to next state
                end
   end

   else if (state == `EX2) begin
      if(branch) begin // if Bxx set PvsWriteEn and go to IF1
                    next_state = `IF1;
                    PvsWriteEn = 1;
                end
                else if(MemRead | MemWrite) begin // if L/S instructions, go to Mem state
                    next_state = `MEM1;
                end
                else begin
                    next_state = `WB; // else, go to WB state (I-type, R-type, JAL, JALR)
                end
   end

   else if (state == `MEM1) begin
      IorD = MemWrite;
                readM = MemRead;
                writeM = MemWrite;
                next_state = `MEM2;
   end

   else if (state == `MEM2) begin
      		readM = 0;
                writeM = 0;
                IorD = 0;
                next_state = `MEM3;
   end
   
   else if (state == `MEM4) begin
    if(MemRead) begin
                    next_state = `WB;    
                end
                else begin
                    next_state = `IF1;
                    PvsWriteEn = 1;
                end
   end

   else if (state == `WB) begin
      next_state = `IF1;
                PvsWriteEn = 1;
   end

   else next_state = state + 1; // else, just go to the next state 

   end

    always @(posedge clk) begin
        if(!reset_n) begin

        end
        else begin
            state <= next_state;
        end
    end
endmodule


