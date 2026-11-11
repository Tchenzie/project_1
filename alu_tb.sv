
`timescale 10ns/10ns
`include "alu.sv"

module alu_tb;

    logic [31:0] a, b;
    logic [3:0] alu_op;
    logic [31:0] result;
    logic eq, lt, ltu;

    alu u0 (
        .a       (a),
        .b       (b),
        .alu_op  (alu_op),
        .result  (result),
        .eq      (eq),
        .lt      (lt),
        .ltu     (ltu)
    );

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        //Test all of pranav's stuff

        // ADD
        a = 32'd10; b = 32'd5; alu_op = 4'b0000;
        #10;
        assert(result == 32'd15) else $error("ADD is bad");

        // SUB
        a = 32'd10; b = 32'd5; alu_op = 4'b1000;
        #10;
        assert(result == 32'd5) else $error("SUB is bad");

        // SLL
        a = 32'd3; b = 32'd2; alu_op = 4'b0001;
        #10;
        assert(result == 32'd12) else $error("SLL is bad");

        // SLT (signed)
        a = 32'hFFFFFFFF; b = 32'd1; alu_op = 4'b0010;
        #10;
        assert(result == 32'd1) else $error("SLT is bad");

        // SLTU (unsigned)
        a = 32'hFFFFFFFF; b = 32'd1; alu_op = 4'b0011;
        #10;
        assert(result == 32'd0) else $error("SLTU is bad");

        // XOR
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0100;
        #10;
        assert(result == 32'hFFFFFFFF) else $error("XOR is bad");

        // SRL (logical right shift)
        a = 32'h80000000; b = 32'd1; alu_op = 4'b0101;
        #10;
        assert(result == 32'h40000000) else $error("SRL is bad");

        // SRA (arithmetic right shift)
        a = 32'h80000000; b = 32'd1; alu_op = 4'b1101;
        #10;
        assert(result == 32'hC0000000) else $error("SRA is bad");

        // OR
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0110;
        #10;
        assert(result == 32'hFFFFFFFF) else $error("OR is bad");

        // AND
        a = 32'hF0F0F0F0; b = 32'h0F0F0F0F; alu_op = 4'b0111;
        #10;
        assert(result == 32'h00000000) else $error("AND is bad");

        // Branch flags: equal
        a = 32'd10; b = 32'd10; alu_op = 4'b0000;
        #10;
        assert(eq == 1'b1) else $error("EQ is bad");
        assert(lt == 1'b0) else $error("LT is bad");
        assert(ltu == 1'b0) else $error("LTU is bad");

        // Branch flags: signed and unsigned comparison
        a = 32'hFFFFFFFF; b = 32'd1;
        #10;
        assert(eq == 1'b0) else $error("EQ is bad");
        assert(lt == 1'b1) else $error("Signed LT is bad");
        assert(ltu == 1'b0) else $error("Unsigned LT is bad");

        // Invalid operation
        a = 32'd10; b = 32'd5; alu_op = 4'b1010;
        #10;
        assert(result == 32'd0) else $error("Default case is bad");

        $display("All ALU tests completed.");
        $finish;
    end

endmodule
