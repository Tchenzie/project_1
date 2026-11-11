`timescale 1ns/1ps

module instruction_reg_tb;

    logic clk = 0;
    logic reset, ir_write;
    logic [31:0] instr_in, instr;
    logic [6:0] opcode, funct7;
    logic [4:0] rd, rs1, rs2;
    logic [2:0] funct3;

    instruction_register dut (.*);

    always #5 clk = ~clk;

    initial begin
        // tests that instruction become NOP when reset = 1
        reset = 1;
        ir_write = 0;
        instr_in = 0;

        @(posedge clk);
        #1 reset = 0;       // waits 1 ns before going to 0

        if (instr != 32'h00000013)
            $display("Reset FAILED");
        else
            $display("Reset PASSED");


        // tests that instruction loads when ir_write = 1
        instr_in = 32'h002081B3;
        ir_write = 1;

        @(posedge clk);
        #1;

        if (instr != 32'h002081B3)
            $display("Load FAILED");
        else
            $display("Load PASSED");



        // tests if R-type instruction fields can be extracted
        if (opcode != 7'b0110011 ||
            rd != 3 ||
            rs1 != 1 ||
            rs2 != 2 ||
            funct3 != 0 ||
            funct7 != 0)
            $display("R-type fields FAILED");
        else
            $display("R-type fields PASSED");


        // tests that the instruction holds when ir_write = 0
        ir_write = 0;
        instr_in = 32'hFFFFFFFF;

        @(posedge clk);
        #1;

        if (instr != 32'h002081B3)
            $display("Hold FAILED");
        else
            $display("Hold PASSED");

        reset = 1;
        ir_write = 1;


        // tests that reset overrides ir_write
        @(posedge clk);
        #1;

        if (instr != 32'h00000013)
            $display("Reset priority FAILED");
        else
            $display("Reset priority PASSED");

        $finish;
    end

endmodule
