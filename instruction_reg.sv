// 32-bit register to temporarily store the instruction fetched from instruction memory
module instruction_reg (
    input  logic        clk,
    input  logic        reset,      // active low if using iceblinkpico
    input  logic        ir_write,   // load enable from control FSM
    input  logic [31:0] instr_in,   // from instruction memory

    output logic [31:0] instr,      // full instruction
    output logic [6:0]  opcode,     // identifies general instruction type      
    output logic [4:0]  rd,         // destination register
    output logic [2:0]  funct3,     // identifies operation
    output logic [4:0]  rs1,        // 1st source register
    output logic [4:0]  rs2,        // 2nd source register
    output logic [6:0]  funct7      // identifies operation further
);

    // 0x00000013 = addi x0, x0, 0 (No Operation), reset value
    localparam logic [31:0] NOP = 32'h0000_0013;

    always_ff @(posedge clk) begin
        if (reset)
            instr <= NOP;           
        else if (ir_write)
            instr <= instr_in;      
    end

    // Combinational assignments for each field
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

endmodule
