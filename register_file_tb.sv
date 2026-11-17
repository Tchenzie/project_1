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
    logic [4:0] rs1_addr;
    logic [4:0] rs2_addr;
    logic [4:0] write_addr;

    logic [31:0] write_data;
    logic write_enable;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    integer i;

    register_file u0 (
        .clk(clk),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .write_addr(write_addr),
        .write_data(write_data),
        .write_enable(write_enable),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    initial begin
        rs1_addr = 0;
        rs2_addr = 0;
        write_addr = 0;
        write_data = 0;
        write_enable = 0;

        #1;


        $display("test 1, initialization");

        for(i = 0; i < 32; i = i + 1) begin
            rs1_addr = i;
            #1;

            if(rs1_data === 32'd0)
                $display("passeded: Register %0d is 0", i);
            else
                $display("failed: Register %0d contains %d", i, rs1_data);
        end

        $display("\ntest 2, writing to a register");

        @(negedge clk);
        write_enable = 1;
        write_addr = 3;
        write_data = 100;

        @(posedge clk);
        #1;
        $display("\ntest 3, reading register 3");

        write_enable = 0;
        rs1_addr = 3;
        #1;

        if (rs1_data === 32'd100)
            $display("passed: Register 3 contains 100");
        else
            $display("failed: reg 3 should be 100, but its %d", rs1_data);

        $display("\ntest 4: Two simultaneous read ports");

        @(negedge clk);
        write_enable = 1;
        write_addr = 10;
        write_data = 200;

        @(posedge clk);
        #1;
        write_enable = 0;
        rs1_addr = 3;
        rs2_addr = 10;
        #1;

        if (rs1_data === 32'd100 && rs2_data === 32'd200)
            $display("passed: Both of the read ports");
        else
            $display("failed: rs1=%d rs2=%d", rs1_data, rs2_data);

        $display("\ntest 5: Write protection for x0");

        @(negedge clk);
        write_enable = 1;
        write_addr = 0;
        write_data = 999;

        @(posedge clk);
        #1;
        write_enable = 0;
        rs1_addr = 0;
        #1;

        if (rs1_data === 32'd0)
            $display("passed: x0 remains zero");
        else
            $display("failed: x0 contains %d", rs1_data);

        $display("\ntest 6: Write enable");

        @(negedge clk);
        write_enable = 0;
        write_addr = 3;
        write_data = 999;

        @(posedge clk);
        #1;

        rs1_addr = 3;
        #1;
        if (rs1_data === 32'd100)
            $display("passed: Register unchanged when write_enable is low");
        else
            $display("failed: Register changed unexpectedly");

        $display("\ntest 7: Overwriting register 3");

        @(negedge clk);
        write_enable = 1;
        write_addr = 3;
        write_data = 300;

        @(posedge clk);
        #1;

        write_enable = 0;
        rs1_addr = 3;
        #1;

        if (rs1_data === 32'd300)
            $display("passed: Register 3 successfully overwritten");
        else
            $display("failed: Expected 300, got %d", rs1_data);

        $display("\n All tests are done");

        $finish;
    end

    always begin
        #4;
        clk = ~clk;
    end

endmodule
