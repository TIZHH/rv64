// Modular single-cycle RV64I core.
//
// Port naming convention: every module port carries a directional suffix so
// that an instantiation reads unambiguously.
//
//   *_i  : input  to the module
//   *_o  : output from the module
//
// Internal wires that only connect two modules are named for the value they
// carry (for example `alu_result`); the direction is visible at the
// instantiation through the port name.
module single_cycle_core (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic [31:0] instruction_i,
    input  logic [63:0] data_read_data_i,
    output logic [63:0] pc_o,
    output logic [63:0] data_address_o,
    output logic        data_read_enable_o,
    output logic [63:0] data_write_data_o,
    output logic [7:0]  data_write_mask_o,
    output logic        data_write_enable_o,
    output logic        illegal_instruction_o,
    output logic [63:0] debug_x10_o,
    output logic [63:0] debug_x31_o
);

    logic        valid;
    logic        reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        alu_src_imm;
    logic        branch;
    logic        jump;
    logic        jump_register;
    logic [2:0]  branch_type;
    logic [2:0]  memory_size;
    logic        memory_unsigned;
    logic [4:0]  alu_operation;
    logic [2:0]  writeback_source;
    logic [63:0] immediate;
    logic [63:0] register_a;
    logic [63:0] register_b;
    logic [63:0] alu_right;
    logic [63:0] alu_result;
    logic [63:0] load_value;
    logic [63:0] writeback_data;
    logic [63:0] next_pc;
    logic        branch_taken;

    decoder instruction_decoder (
        .instruction(instruction_i),
        .valid(valid),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_src_imm(alu_src_imm),
        .branch(branch),
        .jump(jump),
        .jump_register(jump_register),
        .branch_type(branch_type),
        .memory_size(memory_size),
        .memory_unsigned(memory_unsigned),
        .alu_operation(alu_operation),
        .writeback_source(writeback_source),
        .immediate(immediate)
    );

    regfile register_file (
        .clk(clk_i),
        .reset(reset_i),
        .write_enable(reg_write && valid),
        .write_address(instruction_i[11:7]),
        .write_data(writeback_data),
        .read_address_a(instruction_i[19:15]),
        .read_address_b(instruction_i[24:20]),
        .read_data_a(register_a),
        .read_data_b(register_b),
        .debug_x10(debug_x10_o),
        .debug_x31(debug_x31_o)
    );

    assign alu_right = alu_src_imm ? immediate : register_b;

    alu arithmetic_logic_unit (
        .operation(alu_operation),
        .left(register_a),
        .right(alu_right),
        .result(alu_result)
    );

    branch_unit branch_comparator (
        .branch_type_i(branch_type),
        .left_i(register_a),
        .right_i(register_b),
        .taken_o(branch_taken)
    );

    memory_access memory_formatter (
        .mem_read_i(mem_read && valid),
        .mem_write_i(mem_write && valid),
        .memory_size_i(memory_size),
        .memory_unsigned_i(memory_unsigned),
        .byte_offset_i(alu_result[2:0]),
        .store_value_i(register_b),
        .read_data_i(data_read_data_i),
        .load_value_o(load_value),
        .write_data_o(data_write_data_o),
        .write_mask_o(data_write_mask_o),
        .read_enable_o(data_read_enable_o),
        .write_enable_o(data_write_enable_o)
    );

    writeback_mux writeback_selector (
        .source_i(writeback_source),
        .alu_result_i(alu_result),
        .load_value_i(load_value),
        .pc_i(pc_o),
        .immediate_i(immediate),
        .writeback_data_o(writeback_data)
    );

    next_pc_logic next_pc_selector (
        .pc_i(pc_o),
        .immediate_i(immediate),
        .register_a_i(register_a),
        .branch_i(branch),
        .branch_taken_i(branch_taken),
        .jump_i(jump),
        .jump_register_i(jump_register),
        .next_pc_o(next_pc)
    );

    pc_register program_counter (
        .clk_i(clk_i),
        .reset_i(reset_i),
        .next_pc_i(next_pc),
        .pc_o(pc_o)
    );

    assign data_address_o = alu_result;
    assign illegal_instruction_o = !valid;

endmodule
