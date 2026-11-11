module register_file(
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
    initial for(i=0;i<32;i=i+1) registers[i]=32'b0; // power-on reset all zero

    //
    always @(posedge clk)
        if (write_enable && write_addr != 5'd0) registers[write_addr] <= write_data;

    // assign
    assign rs1_data = (rs1_data == 5'd0) ? 32'd0 : registers[rs1_data];
    assign rs2_data = (raddr2 == 5'd0) ? 32'd0 : registers[rs2_data];

endmodule
