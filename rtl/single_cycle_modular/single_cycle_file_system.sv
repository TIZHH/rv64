// File-backed single-cycle system: separate instruction and data memories,
// each initialized from a hex image with $readmemh.
//
// Ports follow the same convention as the core:
//   *_i = input, *_o = output.
module single_cycle_file_system #(
    parameter integer INSTRUCTION_WORDS = 256,
    parameter integer DATA_BYTES = 4096,
    parameter string  INSTRUCTION_IMAGE = "sim/images/instruction.hex",
    parameter string  DATA_IMAGE = "sim/images/data.hex"
) (
    input  logic        clk_i,
    input  logic        reset_i,
    output logic [63:0] pc_o,
    output logic        illegal_instruction_o,
    output logic [63:0] debug_x10_o,
    output logic [63:0] debug_x31_o,
    output logic [63:0] debug_memory_word_o
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
        .address_i(pc_o),
        .instruction_o(instruction)
    );

    single_cycle_core core (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .instruction_i(instruction),
        .data_read_data_i(data_read_data),
        .pc_o(pc_o),
        .data_address_o(data_address),
        .data_read_enable_o(data_read_enable),
        .data_write_data_o(data_write_data),
        .data_write_mask_o(data_write_mask),
        .data_write_enable_o(data_write_enable),
        .illegal_instruction_o(illegal_instruction_o),
        .debug_x10_o(debug_x10_o),
        .debug_x31_o(debug_x31_o)
    );

    data_memory #(
        .BYTES(DATA_BYTES),
        .IMAGE_FILE(DATA_IMAGE)
    ) data_store (
        .clk_i(clk_i),
        .address_i(data_address),
        .read_enable_i(data_read_enable),
        .read_data_o(data_read_data),
        .write_data_i(data_write_data),
        .write_mask_i(data_write_mask),
        .write_enable_i(data_write_enable),
        .debug_word_o(debug_memory_word_o)
    );

endmodule
