module program_counter(
    input logic clk,
    input logic reset,
    input logic pc_write, // something tells pc when to write
    output logic [31:0] pc, //holds curent instruction address (Program counter pc)
    //it is not one of the 32 registers, its a separate one
//each instruction is 32 bits, each instruction address is 32 bits
    output logic [31:0] pc_next //holds address of next instruction

);
always_ff @(posedge clk) begin //update instruction on the positive edge of the clock
    if (reset)
        pc <=  32'b0;
    else if (pc_write)
        pc <= pc_next;
end

endmodule