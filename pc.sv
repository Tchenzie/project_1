module program_counter(
    input logic clk,
    input logic reset,
    input logic pc_write, // something tells pc when to write
    input logic [31:0] pc_next, //holds address of next instruction

    output logic [31:0] pc //holds curent instruction address (Program counter pc)
    //it is not one of the 32 registers, its a separate one
//each instruction is 32 bits, each instruction address is 32 bits

);
always_ff @(posedge clk) begin //update instruction on the positive edge of the clock
    if (reset)
        pc <=  32'h0000_1000;
    else if (pc_write)
        pc <= pc_next;
end

endmodule
