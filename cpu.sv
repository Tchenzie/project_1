module cpu (
    input  logic clk,
    input  logic reset,          
    output logic led, red, green, blue
);
    logic [31:0] pc, alu_out, alu_result;
    logic [31:0] instr, imm_ext, imem_data_out;
    logic [2:0]  imm_src;
    logic [31:0] rd1, rd2, src_b;
    logic [6:0]  op, funct7;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;

    logic        ir_write, alu_out_write, reg_write, pc_write, alu_src_b;
    logic [3:0]  alu_control;   
    logic [2:0]  state_out;
    logic [1:0]  alu_src_a;
    logic [31:0] src_a;

    // PC
    logic [31:0] pc_next;
    //branches and jumps
    logic [31:0] writeback_data;
    logic [31:0] link_addr;
    logic branch_taken;
    logic branch_en, jump_en;

    logic alu_eq;
    logic alu_lt;
    logic alu_ltu;

    program_counter u_pc (
        .clk(clk),
        .reset(reset),
        .pc_write(pc_write),
        .pc_next(pc_next),
        .pc(pc)
    );

    // Memory 
    memory u_mem (
        .clk(clk),
        .funct3(3'b010),
        .dmem_wren(1'b0),
        .dmem_address(32'd0),
        .dmem_data_in(32'd0),
        .imem_address(pc),
        .imem_data_out(imem_data_out),
        .dmem_data_out(),
        .reset(),                  
        .led(led), .red(red), .green(green), .blue(blue)
    );

    instruction_reg u_ir (
        .clk, .reset, .ir_write, .instr_in(imem_data_out),
        .instr, .op, .rd, .funct3, .rs1, .rs2, .funct7
    );

    immediate_generator u_imm (
        .instr(instr), .imm_src(imm_src), .imm_ext(imm_ext)
    );

    // Combination decode
    always_comb begin
        case (op)
            7'b0100011: imm_src = 3'b001; // STORE
            7'b1100011: imm_src = 3'b010; // BRANCH
            7'b0110111: imm_src = 3'b011; // LUI
            7'b0010111: imm_src = 3'b011; // AUIPC
            7'b1101111: imm_src = 3'b100; // JAL
            default:    imm_src = 3'b000; // I-type
        endcase
    end

    register_file u_rf (
        .clk,
        .a1(rs1), .a2(rs2),
        .a3(rd), .wd3(writeback_data), .we3(reg_write),
        .rd1(rd1), .rd2(rd2)
    );

    assign src_b = alu_src_b ? imm_ext : rd2;
    alu u_alu (
        .src_a(src_a), .src_b(src_b), .alu_control(alu_control),
        .alu_result(alu_result), .eq(alu_eq), .lt(alu_It), .ltu(alu_ltu)
    );

    always_ff @(posedge clk)
        if (alu_out_write) alu_out <= alu_result;

    fsm u_fsm (
        .clk, .reset, .op, .funct3, funct7_5(instr[30]),
        .ir_write(ir_write), .alu_out_write(alu_out_write), .reg_write(reg_write), .pc_write(pc_write),
        .alu_src_b(alu_src_b), .alu_control(alu_control), alu_src_a(alu_src_a), 
        .branch_en(branch_en), .jump_en(jump_en), .state_out(state_out)
    );

    always_comb begin
        case (alu_src_a)
            2'd1:    src_a = pc;
            2'd2:    src_a = 32'd0;
            default: src_a = rd1;
        endcase
    end

    always_comb begin
        if (jump_en)
            writeback_data = link_addr;
        else
            writeback_data = alu_out;
    end
    
    //Jump module
    branch_jump u_branch_jump (
    .pc(pc),
    .rs1(rd1),
    .imm_ext(imm_ext),

    .op(op),
    .funct3(funct3),

    .eq(alu_eq),
    .lt(alu_lt),
    .ltu(alu_ltu),

    .pc_next(pc_next),
    .link_addr(link_addr),
    .branch_taken(branch_taken)
    );

endmodule
