module immediate_generator(
    //takes out and expands the value from an instruction
    input logic [31:0] instruction, //the 32bit instruction
    input logic [2:0] imm_type, //5 values needs 3 bits (2^3 = 8 but 2^2=4)
    output logic [31:0] instruction_imm
);

always_comb begin
//I type
case (imm_type)
    3'b000: assign instruction_imm = {{20{instruction[31]}},instruction[31:20]};
//S-Type
    3'b001: assign instruction_imm = {{20{instruction[31]}},{{instruction[31:25]}},{instruction[11:7]}};

//B-Type
    3'b010: assign instruction_imm = {{20{instruction[31]}},instruction[7],{instruction[30:25]},{instruction[11:8]},{1{1'b0}}};

//U-type
    3'b011: assign instruction_imm = {instruction[31:12],{{12{1'b0}}}};

//J-Type
    3'b100: assign instruction_imm = {{12{instruction[31]}},instruction[19:12],instruction[20], instruction[30:21],{{1{1'b0}}}};
//Default case
    default: instruction_imm = 32'b0;
endcase
end
endmodule