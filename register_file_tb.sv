/*Few things to test
1. are the initial registers equal to zero
2. can it properly write a value to a register
3. can it read register
4. read 2 ports simultaneously
5. write to x0 and see if its still 0
6. write enable should stop value from changing
7. should be able to overwrite value in a register

*/

`timescale 1ns/1ps
`include "register_file.sv"

module register_file_tb;
    logic clk = 0;
    logic [4:0] a1;
    logic [4:0] a2;
    logic [4:0] a3;

    logic [31:0] wd3;
    logic we3;

    logic [31:0] rd1;
    logic [31:0] rd2;

    integer i;

    register_file u0 (
        .clk(clk),
        .a1(a1),
        .a2(a2),
        .a3(a3),
        .wd3(wd3),
        .we3(we3),
        .rd1(rd1),
        .rd2(rd2)
    );

    initial begin
        a1 = 0;
        a2 = 0;
        a3 = 0;
        wd3 = 0;
        we3 = 0;

        #1;


        $display("test 1, initialization");

        for(i = 0; i < 32; i = i + 1) begin
            a1 = i;
            #1;

            if(rd1 === 32'd0)
                $display("passeded: Register %0d is 0", i);
            else
                $display("failed: Register %0d contains %d", i, rd1);
        end

        $display("\ntest 2, writing to a register");

        @(negedge clk);
        we3 = 1;
        a3 = 3;
        wd3 = 100;

        @(posedge clk);
        #1;
        $display("\ntest 3, reading register 3");

        we3 = 0;
        a1 = 3;
        #1;

        if (rd1 === 32'd100)
            $display("passed: Register 3 contains 100");
        else
            $display("failed: reg 3 should be 100, but its %d", rd1);

        $display("\ntest 4: Two simultaneous read ports");

        @(negedge clk);
        we3 = 1;
        a3 = 10;
        wd3 = 200;

        @(posedge clk);
        #1;
        we3 = 0;
        a1 = 3;
        a2 = 10;
        #1;

        if (rd1 === 32'd100 && rd2 === 32'd200)
            $display("passed: Both of the read ports");
        else
            $display("failed: rs1=%d rs2=%d", rd1, rd2);

        $display("\ntest 5: Write protection for x0");

        @(negedge clk);
        we3 = 1;
        a3 = 0;
        wd3 = 999;

        @(posedge clk);
        #1;
        we3 = 0;
        a1 = 0;
        #1;

        if (rd1 === 32'd0)
            $display("passed: x0 remains zero");
        else
            $display("failed: x0 contains %d", rd1);

        $display("\ntest 6: Write enable");

        @(negedge clk);
        we3 = 0;
        a3 = 3;
        wd3 = 999;

        @(posedge clk);
        #1;

        a1 = 3;
        #1;
        if (rd1 === 32'd100)
            $display("passed: Register unchanged when we3 is low");
        else
            $display("failed: Register changed unexpectedly");

        $display("\ntest 7: Overwriting register 3");

        @(negedge clk);
        we3 = 1;
        a3 = 3;
        wd3 = 300;

        @(posedge clk);
        #1;

        we3 = 0;
        a1 = 3;
        #1;

        if (rd1 === 32'd300)
            $display("passed: Register 3 successfully overwritten");
        else
            $display("failed: Expected 300, got %d", rd1);

        $display("\n All tests are done");

        $finish;
    end

    always begin
        #4;
        clk = ~clk;
    end

endmodule
