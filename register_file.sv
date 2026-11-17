module register_file(
    //a register file takes 2 read values, sends to alu for the operation, alu sends back here (which stores result)
    input logic clk,

    // ok read address for 1 and 2. write address that are 32 bits. store 32 bit registers 32 bits wide.
    input logic [4:0] rs1_addr , //read address first register read
    input logic [4:0] rs2_addr, //read address 2nd register read
    input logic [4:0] write_addr, //Writing the address rd

    input logic [31:0] write_data,
    input logic write_enable,

    output logic [31:0] rs1_data, //register source 1's data
    output logic [31:0] rs2_data //reg souce 2 data
);
    logic [31:0] registers[0:31]; //The 32 bit reg with 32 bits each reg
    integer i;
    initial begin
    for(i=0;i<32;i=i+1)
        registers[i]=32'b0; // power-on reset all zero
    end
    //
    always @(posedge clk)
        if (write_enable && write_addr != 5'd0) begin
        registers[write_addr] <= write_data;
        end
     //if rs1 address is 0, assign 32 bits of zero to rs1 data, otherwise take the address data from the register.
    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : registers[rs1_addr];
    //same for rs2
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : registers[rs2_addr];

endmodule
