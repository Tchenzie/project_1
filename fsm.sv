// Multicycle control FSM for RV32I (fetch + addi only).
module fsm (
    input  logic       clk,
    input  logic       reset,        // synchronous, active high

    // From instruction register
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,

    // Control outputs
    output logic       ir_write,        // connect instruction memory output to IR
    output logic       alu_out_write,   // connect ALU result to ALUOut register
    output logic       reg_write,       // write result to register file
    output logic       pc_write,        // PC <= PC + 4
    output logic       alu_src_b,       // 0 = rs2, 1 = immediate
    output logic [1:0] alu_op,          // 00 = add (extend later)
    output logic [1:0] alu_src_a,       // 0 = rs1, 1 = PC, 2 = zero

    // Output for testbench use
    output logic [2:0] state_out
);

    localparam logic [6:0] OP_IMM = 7'b0010011;
    localparam logic [6:0] OP_LUI   = 7'b0110111;
    localparam logic [6:0] OP_AUIPC = 7'b0010111;

    typedef enum logic [2:0] {
        S_FETCH      = 3'd0,        // PC drives instruction memory address
        S_FETCH_WAIT = 3'd1,        // memory data valid; latch into IR
        S_DECODE     = 3'd2,        // read regfile, generate immediate
        S_EXECUTE    = 3'd3,        // ALU computes
        S_WRITEBACK  = 3'd4         // write rd, advance PC
    } state_t;

    state_t state, next_state;

    // Instruction decoding
    logic is_addi;
    assign is_addi = (opcode == OP_IMM) && (funct3 == 3'b000);

    logic is_lui, is_auipc, writes_rd_imm;
    assign is_lui        = (opcode == OP_LUI);
    assign is_auipc      = (opcode == OP_AUIPC);
    assign writes_rd_imm = is_addi | is_lui | is_auipc;

    // State register
    always_ff @(posedge clk) begin
        if (reset) state <= S_FETCH;
        else       state <= next_state;
    end

    // Next-state logic
    always_comb begin
        next_state = state;
        case (state)
            S_FETCH:      next_state = S_FETCH_WAIT;
            S_FETCH_WAIT: next_state = S_DECODE;
            S_DECODE: next_state = writes_rd_imm ? S_EXECUTE : S_WRITEBACK;
            S_EXECUTE: begin
                alu_src_b     = 1'b1;
                alu_op        = 2'b00;
                alu_out_write = 1'b1;
                if (is_lui)        alu_src_a = 2'd2;   // 0 + imm
                else if (is_auipc) alu_src_a = 2'd1;   // PC + imm
            end
            S_WRITEBACK: begin
                pc_write  = 1'b1;
                reg_write = writes_rd_imm;
            end
            default:      next_state = S_FETCH;
        endcase
    end

    // Output logic (Moore)
    always_comb begin
        ir_write      = 1'b0;
        alu_out_write = 1'b0;
        reg_write     = 1'b0;
        pc_write      = 1'b0;
        alu_src_b     = 1'b0;
        alu_op        = 2'b00;

        case (state)
            S_FETCH_WAIT: ir_write = 1'b1;

            S_EXECUTE: begin
                alu_src_b     = 1'b1;       // rs1 + imm
                alu_op        = 2'b00;      // add
                alu_out_write = 1'b1;
            end

            S_WRITEBACK: begin
                pc_write  = 1'b1;
                reg_write = is_addi;        // only addi writes rd for now
            end

            default: ;
        endcase
    end

    assign state_out = state;

endmodule
