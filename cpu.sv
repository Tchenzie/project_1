module cpu (
    input  logic clk,
    input  logic reset,          
    output logic led, red, green, blue
);
    logic [31:0] pc, alu_out, alu_result;
    logic [31:0] instr, imm_ext, imem_data_out;
    logic [31:0] rd1, rd2, src_b;
    logic [6:0]  op, funct7;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;

    logic        ir_write, alu_out_write, reg_write, pc_write, alu_src_b;
    logic [1:0]  alu_op;     
    logic [2:0]  state_out;
    logic [1:0]  alu_src_a;
    logic [31:0] src_a;

    localparam logic [3:0] ALU_ADD = 4'b0000;

    // PC (resets to 0x1000)
    always_ff @(posedge clk) begin
        if (reset)         pc <= 32'h0000_1000;
        else if (pc_write) pc <= pc + 32'd4;
    end

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

    immediate_generator u_imm (.instr(instr), .imm_ext(imm_ext));          // placeholder port names until immediate generator is uploaded

    register_file u_rf (
        .clk,
        .a1(rs1), .a2(rs2),
        .a3(rd), .wd3(alu_out), .we3(reg_write),
        .rd1, .rd2
    );

    assign src_b = alu_src_b ? imm_ext : rd2;
    alu u_alu (
        .src_a(rd1), .src_b(src_b), .alu_control(ALU_ADD),
        .alu_result(alu_result), .eq(), .lt(), .ltu()
    );

    always_ff @(posedge clk)
        if (alu_out_write) alu_out <= alu_result;

    fsm u_fsm (
        .clk, .reset, .op, .funct3,
        .ir_write, .alu_out_write, .reg_write, .pc_write,
        .alu_src_b, .alu_op(alu_op), .state_out
    );

    always_comb begin
        case (alu_src_a)
            2'd1:    src_a = pc;
            2'd2:    src_a = 32'd0;
            default: src_a = rd1;
        endcase
    end

endmodule
