`include "memory.sv"

module top (
    input  logic clk,
    output logic LED, RGB_R, RGB_G, RGB_B
);
    logic [3:0] reset_counter = 4'd0;    // 4-bit reset counter 
    logic reset;
    
    assign reset = ~&reset_counter;

    // while reset=1, the counter increases by 1 on each rising edge
    // makes sure the CPU starts at the first instruction
    always_ff @(posedge clk) 
        if (reset) 
            reset_counter <= reset_counter + 1;

    logic led, red, green, blue;

    // instantiate the CPU
    cpu #(.IMEM_INIT("rv32i_test")) u_cpu (.clk, .reset, .led, .red, .green, .blue);

    assign LED   = ~led;
    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;
endmodule
