module single_cycle_file_system #(
    parameter integer INSTRUCTION_WORDS = 256,
    parameter integer DATA_BYTES = 4096,
    parameter string  INSTRUCTION_IMAGE = "sim/images/instruction.hex",
    parameter string  DATA_IMAGE = "sim/images/data.hex"
) (
    input  logic        clk,
    input  logic        reset,
    output logic [63:0] pc,
    output logic        illegal_instruction,
    output logic [63:0] debug_x10,
    output logic [63:0] debug_x31,
    output logic [63:0] debug_memory_word
);

    logic [31:0] instruction;
    logic [63:0] data_address;
    logic        data_read_enable;
    logic [63:0] data_read_data;
    logic [63:0] data_write_data;
    logic [7:0]  data_write_mask;
    logic        data_write_enable;

    instruction_memory #(
        .WORDS(INSTRUCTION_WORDS),
        .IMAGE_FILE(INSTRUCTION_IMAGE)
    ) instruction_store (
        .address(pc),
        .instruction(instruction)
    );

    single_cycle_core core (
        .clk(clk),
        .reset(reset),
        .instruction(instruction),
        .data_read_data(data_read_data),
        .pc(pc),
        .data_address(data_address),
        .data_read_enable(data_read_enable),
        .data_write_data(data_write_data),
        .data_write_mask(data_write_mask),
        .data_write_enable(data_write_enable),
        .illegal_instruction(illegal_instruction),
        .debug_x10(debug_x10),
        .debug_x31(debug_x31)
    );

    data_memory #(
        .BYTES(DATA_BYTES),
        .IMAGE_FILE(DATA_IMAGE)
    ) data_store (
        .clk(clk),
        .address(data_address),
        .read_enable(data_read_enable),
        .read_data(data_read_data),
        .write_data(data_write_data),
        .write_mask(data_write_mask),
        .write_enable(data_write_enable),
        .debug_word(debug_memory_word)
    );

endmodule
