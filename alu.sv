
// alu_op uses the instruction's own bits: { funct7[5], funct3 }.
// For R-type, pass { instr[30], instr[14:12] } straight in.
// For I-type ALU ops, use { 1'b0, funct3 }, except srai which needs { instr[30], funct3 }.
// For loads, stores, jumps, auipc, lui, and address math, use ALU_ADD.
//
// The eq / lt / ltu outputs are for branches:
//   beq  -> eq
//   bne  -> !eq
//   blt  -> lt
//   bge  -> !lt
//   bltu -> ltu
//   bgeu -> !ltu

// Ports: two 32-bit inputs, a 4-bit operation select, the 32-bit result, and three branch flags.
module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_op,
    output logic [31:0] result,
    output logic        eq,
    output logic        lt,
    output logic        ltu
);

    // Named codes for each operation, built from {instr[30], funct3} so the decoder can pass bits straight in.
    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_SUB  = 4'b1000;
    localparam logic [3:0] ALU_SLL  = 4'b0001;
    localparam logic [3:0] ALU_SLT  = 4'b0010;
    localparam logic [3:0] ALU_SLTU = 4'b0011;
    localparam logic [3:0] ALU_XOR  = 4'b0100;
    localparam logic [3:0] ALU_SRL  = 4'b0101;
    localparam logic [3:0] ALU_SRA  = 4'b1101;
    localparam logic [3:0] ALU_OR   = 4'b0110;
    localparam logic [3:0] ALU_AND  = 4'b0111;

    // Shift amount signal, since a 32-bit value can only shift 0 to 31 places.
    logic [4:0] shamt;

    // Use only the bottom 5 bits of b as the shift amount, as the RISC-V spec requires.
    assign shamt = b[4:0];

    // Branch flags that are always computed: equal, signed less than, and unsigned less than.
    assign eq = (a == b);
    assign lt = ($signed(a) < $signed(b));
    assign ltu = (a < b);

    // Combinational block that picks which operation's answer goes to result based on alu_op.
    always_comb begin
        case (alu_op)
            // Add a and b (also used for addresses, jumps, auipc, and lui).
            ALU_ADD: begin
                result = a + b;
            end
            // Subtract b from a.
            ALU_SUB: begin
                result = a - b;
            end
            // Shift a left by shamt, filling the bottom with 0s.
            ALU_SLL: begin
                result = a << shamt;
            end
            // Output 1 if a < b as signed numbers, otherwise 0.
            ALU_SLT: begin
                result = {31'b0, lt};
            end
            // Output 1 if a < b as unsigned numbers, otherwise 0.
            ALU_SLTU: begin
                result = {31'b0, ltu};
            end
            // Bitwise XOR of a and b.
            ALU_XOR: begin
                result = a ^ b;
            end
            // Logical right shift, filling the top with 0s.
            ALU_SRL: begin
                result = a >> shamt;
            end
            // Arithmetic right shift, filling the top with copies of the sign bit so negatives stay negative.
            ALU_SRA: begin
                result = $unsigned($signed(a) >>> shamt);
            end
            // Bitwise OR of a and b.
            ALU_OR: begin
                result = a | b;
            end
            // Bitwise AND of a and b.
            ALU_AND: begin
                result = a & b;
            end
            // Output 0 for unused codes so the tool doesn't create an accidental latch.
            default: begin
                result = 32'b0;
            end
        endcase
    end

endmodule
