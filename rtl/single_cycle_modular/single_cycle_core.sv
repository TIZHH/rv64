module single_cycle_core (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instruction,
    input  logic [63:0] data_read_data,
    output logic [63:0] pc,
    output logic [63:0] data_address,
    output logic        data_read_enable,
    output logic [63:0] data_write_data,
    output logic [7:0]  data_write_mask,
    output logic        data_write_enable,
    output logic        illegal_instruction,
    output logic [63:0] debug_x10,
    output logic [63:0] debug_x31
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
        .instruction(instruction),
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
        .clk(clk),
        .reset(reset),
        .write_enable(reg_write && valid),
        .write_address(instruction[11:7]),
        .write_data(writeback_data),
        .read_address_a(instruction[19:15]),
        .read_address_b(instruction[24:20]),
        .read_data_a(register_a),
        .read_data_b(register_b),
        .debug_x10(debug_x10),
        .debug_x31(debug_x31)
    );

    assign alu_right = alu_src_imm ? immediate : register_b;

    alu arithmetic_logic_unit (
        .operation(alu_operation),
        .left(register_a),
        .right(alu_right),
        .result(alu_result)
    );

    branch_unit branch_comparator (
        .branch_type(branch_type),
        .left(register_a),
        .right(register_b),
        .taken(branch_taken)
    );

    memory_access memory_formatter (
        .mem_read(mem_read && valid),
        .mem_write(mem_write && valid),
        .memory_size(memory_size),
        .memory_unsigned(memory_unsigned),
        .byte_offset(alu_result[2:0]),
        .store_value(register_b),
        .read_data(data_read_data),
        .load_value(load_value),
        .write_data(data_write_data),
        .write_mask(data_write_mask),
        .read_enable(data_read_enable),
        .write_enable(data_write_enable)
    );

    writeback_mux writeback_selector (
        .source(writeback_source),
        .alu_result(alu_result),
        .load_value(load_value),
        .pc(pc),
        .immediate(immediate),
        .writeback_data(writeback_data)
    );

    next_pc_logic next_pc_selector (
        .pc(pc),
        .immediate(immediate),
        .register_a(register_a),
        .branch(branch),
        .branch_taken(branch_taken),
        .jump(jump),
        .jump_register(jump_register),
        .next_pc(next_pc)
    );

    pc_register program_counter (
        .clk(clk),
        .reset(reset),
        .next_pc(next_pc),
        .pc(pc)
    );

    assign data_address = alu_result;
    assign illegal_instruction = !valid;

endmodule
