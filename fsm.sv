// Multicycle control FSM with ADDI, LIU, AUIPC, and branch/jump
module fsm (
    input  logic       clk,
    input  logic       reset,        

    // From instruction register
    input  logic [6:0] op,
    input  logic [2:0] funct3,
    input  logic       funct7_5,
    
    input logic mem_done,

    // Control outputs
    output logic       ir_write,        
    output logic       alu_out_write,  
    output logic       reg_write,       
    output logic       pc_write,        
    output logic       alu_src_b,       
    output logic [3:0] alu_control,          
    output logic [1:0] alu_src_a,       

    // Branch and jump controls
    output logic       branch_en,
    output logic       jump_en,

    // Output for testbench use
    output logic [2:0] state_out
);

    // Instruction opcodes
    localparam logic [6:0] OP_REG    = 7'b0110011;
    localparam logic [6:0] OP_IMM    = 7'b0010011;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_JALR   = 7'b1100111;

    // ALU source A selections
    localparam logic [1:0] SRC_A_RS1  = 2'b00;
    localparam logic [1:0] SRC_A_PC   = 2'b01;
    localparam logic [1:0] SRC_A_ZERO = 2'b10;

    // load and store
    localparam logic [6:0] OP_LOAD  = 7'b0000011;
    localparam logic [6:0] OP_STORE = 7'b0100011;

    // FSM states
    typedef enum logic [2:0] {
        S_FETCH      = 3'd0,        // PC drives instruction memory address
        S_FETCH_WAIT = 3'd1,        // memory data valid; latch into IR
        S_DECODE     = 3'd2,        // read regfile, generate immediate
        S_EXECUTE    = 3'd3,        // ALU computes
        S_WRITEBACK  = 3'd4,        // write rd, advance PC
        S_BRANCH     = 3'd5,
        S_JUMP       = 3'd6,
        S_MEM        = 3'd7
    } state_t;

    state_t state, next_state;

    // Instruction decoding
    logic is_addi;
    logic is_lui;
    logic is_auipc;
    logic is_alu_reg;
    logic is_alu_imm;
    logic is_branch;
    logic is_jal;
    logic is_jalr;
    logic is_jump;
    logic writes_rd_imm;
    logic is_mem;
    
    assign is_addi = (op == OP_IMM) &&
        (funct3 == 3'b000);
    assign is_lui = (op == OP_LUI);
    assign is_auipc = (op == OP_AUIPC);
    assign is_alu_reg = (op == OP_REG);
    assign is_alu_imm = (op == OP_IMM);
    assign is_branch = (op == OP_BRANCH);
    assign is_jal = (op == OP_JAL);
    assign is_jalr = (op == OP_JALR);
    assign is_jump = is_jal | is_jalr;
    assign writes_rd_imm = is_alu_reg | is_alu_imm | is_lui | is_auipc;
    assign is_mem = (op == OP_LOAD) | (op == OP_STORE);

    // State register
    always_ff @(posedge clk) begin
        if (reset) state <= S_FETCH;
        else       state <= next_state;
    end

    // Next-state logic
    always_comb begin
        next_state = state;
        case (state)
            S_FETCH:      
                next_state = S_FETCH_WAIT;
            
            S_FETCH_WAIT: 
                next_state = S_DECODE;
            
            S_DECODE: begin
                if (is_branch)
                    next_state = S_BRANCH;
                else if (is_jump)
                    next_state = S_JUMP;
                else if (writes_rd_imm | is_mem)
                    next_state = S_EXECUTE;
                else
                    next_state = S_FETCH;
            end
            
            S_EXECUTE:
                next_state = is_mem ? S_MEM : S_WRITEBACK;
            
            S_WRITEBACK:  
                next_state = S_FETCH;
            
            S_BRANCH:     
                next_state = S_FETCH;
            
            S_JUMP:       
                next_state = S_FETCH;

            S_MEM:     
                next_state = mem_done ? S_FETCH : S_MEM;
            
            default:      
                next_state = S_FETCH;
            
        endcase
    end

    // Output logic (Moore FSM)
    always_comb begin
        // Default control signals
        ir_write      = 1'b0;
        alu_out_write = 1'b0;
        reg_write     = 1'b0;
        pc_write      = 1'b0;
        
        alu_src_b     = 1'b0;
        alu_src_a     = SRC_A_RS1;
        alu_control   = 4'b0000;  // ALU_ADD

        branch_en     = 1'b0;
        jump_en       = 1'b0;

        case (state)
            S_FETCH_WAIT: begin 
                ir_write = 1'b1;
            end

            S_EXECUTE: begin
                alu_out_write = 1'b1;

                // R-type instructions
                if (is_alu_reg) begin
                    alu_src_b   = 1'b0;
                    alu_src_a   = SRC_A_RS1;
                    alu_control = {funct7_5, funct3};
                end

                // I-type ALU instructions
                else if (is_alu_imm) begin
                    alu_src_b = 1'b1;
                    alu_src_a = SRC_A_RS1;

                    // SRAI needs funct7[5] = 1
                    if (funct3 == 3'b101)
                        alu_control = {funct7_5, funct3};
                    else
                        alu_control = {1'b0, funct3};
                end

                // LUI
                else if (is_lui) begin
                    alu_src_a   = SRC_A_ZERO;
                    alu_src_b   = 1'b1;
                    alu_control = 4'b0000;
                end

                // AUIPC
                else if (is_auipc) begin
                    alu_src_a   = SRC_A_PC;
                    alu_src_b   = 1'b1;
                    alu_control = 4'b0000;
                end

                // load_store output
                else if (is_mem) begin
                    alu_src_a   = SRC_A_RS1;
                    alu_src_b   = 1'b1;       
                    alu_control = 4'b0000;
                end
            end
            
            S_WRITEBACK: begin
                reg_write = 1'b1;
                pc_write  = 1'b1;   
            end

            // Branch control
            S_BRANCH: begin
                branch_en = 1'b1;
                pc_write  = 1'b1;
            end

            // Jump control
            S_JUMP: begin
                jump_en  = 1'b1;
                pc_write = 1'b1;
                reg_write = 1'b1;
            end

            default: ;
        endcase
    end

    assign state_out = state;

endmodule
