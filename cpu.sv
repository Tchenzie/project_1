module cpu (
    input  logic clk,
    input  logic reset,          
    output logic led, red, green, blue
);
    logic [31:0] pc, alu_out, alu_result;
    logic [31:0] instr, imm, imem_data;
    logic [31:0] rs1_data, rs2_data, alu_b;
    logic [6:0]  opcode, funct7;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;

    logic        ir_write, alu_out_write, reg_write, pc_write, alu_src_b;
    logic [1:0]  fsm_alu_op;     
    logic [2:0]  state_out;
    logic [1:0]  alu_src_a;
    logic [31:0] alu_a;

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
        .imem_data_out(imem_data),
        .dmem_data_out(),
        .reset(),                  
        .led(led), .red(red), .green(green), .blue(blue)
    );

    instruction_register u_ir (
        .clk, .reset, .ir_write, .instr_in(imem_data),
        .instr, .opcode, .rd, .funct3, .rs1, .rs2, .funct7
    );

    imm_gen u_imm (.instr(instr), .imm(imm));          // placeholder port names until immediate generator is uploaded

    register_file u_rf (
        .clk,
        .rs1_addr(rs1), .rs2_addr(rs2),
        .write_addr(rd), .write_data(alu_out), .write_enable(reg_write),
        .rs1_data, .rs2_data
    );

    assign alu_b = alu_src_b ? imm : rs2_data;
    alu u_alu (
        .a(rs1_data), .b(alu_b), .alu_op(ALU_ADD),
        .result(alu_result), .eq(), .lt(), .ltu()
    );

    always_ff @(posedge clk)
        if (alu_out_write) alu_out <= alu_result;

    control_fsm u_fsm (
        .clk, .reset, .opcode, .funct3,
        .ir_write, .alu_out_write, .reg_write, .pc_write,
        .alu_src_b, .alu_op(fsm_alu_op), .state_out
    );

    always_comb begin
        case (alu_src_a)
            2'd1:    alu_a = pc;
            2'd2:    alu_a = 32'd0;
            default: alu_a = rs1_data;
        endcase
    end

endmodule
