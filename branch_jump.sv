module branch_jump(
    input logic [31:0] pc,
    input logic [31:0] rs1,
    input logic [31:0] imm_ext,

    input logic [6:0] op,
    input logic [2:0] funct3,

    //Comparng output from Eleanes Alu
    input logic eq,
    input logic lt,
    input logic ltu,

    output logic [31:0] pc_next,
    output logic [31:0] link_addr,
    output logic branch_taken
);

    //opcode instr
    localparam logic [6:0] OP_BRANCH =  7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;

    always_comb begin
        //default is pc_next = pc+4
        pc_next = pc + 32'd4;
        //return jal and jalr address
        link_addr = pc + 32'd4;

        //default: branch taken is false (0)
        branch_taken = 1'b0;

        //if branches
        if (op == OP_BRANCH) begin
            case(funct3)
                3'b000: branch_taken = eq; // BEQ
                3'b001: branch_taken = ~eq; // BNE
                3'b100: branch_taken = lt; // BLT
                3'b101: branch_taken = ~lt; // BGE
                3'b110: branch_taken = ltu; // BLTU
                3'b111: branch_taken = ~ltu;// BGEU
            
            default: branch_taken = 1'b0;
            endcase

            if(branch_taken)
                pc_next = pc + imm_ext;
        end
        //JAL jump
        else if (op==OP_JAL) begin
            pc_next = pc + imm_ext;
        end
        //JALR
        else if (op==OP_JALR) begin
            pc_next = (rs1 + imm_ext) & 32'hFFFFFFFE;
        end
    end
endmodule
