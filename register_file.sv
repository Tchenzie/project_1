module register_file(
    //a register file takes 2 read values, sends to alu for the operation, alu sends back here (which stores result)
    input logic clk,

    // ok read address for 1 and 2. write address that are 32 bits. store 32 bit registers 32 bits wide.
    input logic [4:0] a1 , //read address first register read
    input logic [4:0] a2, //read address 2nd register read
    input logic [4:0] a3, //Writing the address rd

    input logic [31:0] wd3,
    input logic we3,

    output logic [31:0] rd1, //register source 1's data
    output logic [31:0] rd2 //reg souce 2 data
);
    logic [31:0] registers[0:31]; //The 32 bit reg with 32 bits each reg
    integer i;
    initial begin
    for(i=0;i<32;i=i+1)
        registers[i]=32'b0; // power-on reset all zero
    end
    //
    always_ff @(posedge clk)
        if (we3 && a3 != 5'd0) begin
        registers[a3] <= wd3;
        end
     //if rs1 address is 0, assign 32 bits of zero to rs1 data, otherwise take the address data from the register.
    assign rd1 = (a1 == 5'd0) ? 32'd0 : registers[a1];
    //same for rs2
    assign rd2 = (a2 == 5'd0) ? 32'd0 : registers[a2];

endmodule
