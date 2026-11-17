// Load/store unit for the multicycle RV32I CPU (lb, lh, lw, lbu, lhu, sb, sh, sw).
// memory.sv already does byte/halfword selection and sign extension from funct3,
// so this module only sequences the access and selects the register write-back data.
//
// Timing (memory.sv reads take one clock):
//   load:  S_EXECUTE (alu_out <= rs1 + imm) -> LS_READ (address on bus) -> LS_WB (rd <= loaded data)
//   store: S_EXECUTE (alu_out <= rs1 + imm) -> LS_WRITE (mem[alu_out] <= rs2)
//
// Hookup:
//   cpu.sv: memory .funct3(funct3), .dmem_wren(dmem_wren), .dmem_address(alu_out),
//           .dmem_data_in(rs2_data), .dmem_data_out(dmem_data_out);
//           register file .write_data(reg_write_data), .write_enable(reg_write | ls_reg_write);
//           PC advances on (pc_write | mem_done).
//   fsm.sv: loads/stores go S_DECODE -> S_EXECUTE -> a wait state that returns to S_FETCH when mem_done.
module load_store (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,          // connect to alu_out_write (high only in S_EXECUTE)
    input  logic [6:0]  opcode,
    input  logic [31:0] alu_out,        // rs1 + imm from S_EXECUTE
    input  logic [31:0] dmem_data_out,  // from memory.sv
    output logic        dmem_wren,      // to memory.sv
    output logic        ls_reg_write,   // write loaded data to rd
    output logic        mem_done,       // access finished: advance PC, return to fetch
    output logic [31:0] reg_write_data  // to register file write_data
);

    localparam logic [6:0] OP_LOAD  = 7'b0000011;
    localparam logic [6:0] OP_STORE = 7'b0100011;

    typedef enum logic [1:0] {
        LS_IDLE  = 2'd0,
        LS_READ  = 2'd1,                // alu_out drives data memory address
        LS_WB    = 2'd2,                // dmem_data_out valid; write rd
        LS_WRITE = 2'd3                 // write rs2 to data memory
    } ls_state_t;

    ls_state_t ls_state;

    always_ff @(posedge clk) begin
        if (reset)
            ls_state <= LS_IDLE;
        else if (start && (opcode == OP_LOAD))
            ls_state <= LS_READ;
        else if (start && (opcode == OP_STORE))
            ls_state <= LS_WRITE;
        else if (ls_state == LS_READ)
            ls_state <= LS_WB;
        else
            ls_state <= LS_IDLE;
    end

    assign dmem_wren      = (ls_state == LS_WRITE);
    assign ls_reg_write   = (ls_state == LS_WB);
    assign mem_done       = (ls_state == LS_WB) || (ls_state == LS_WRITE);
    assign reg_write_data = ls_reg_write ? dmem_data_out : alu_out;

endmodule
