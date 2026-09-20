module pipeline_cpu (
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

    logic if_id_valid;
    logic [63:0] if_id_pc;
    logic [31:0] if_id_instruction;

    logic id_ex_valid;
    logic [63:0] id_ex_pc;
    logic [63:0] id_ex_register_a;
    logic [63:0] id_ex_register_b;
    logic [63:0] id_ex_immediate;
    logic [4:0] id_ex_rs1;
    logic [4:0] id_ex_rs2;
    logic [4:0] id_ex_rd;
    logic [2:0] id_ex_branch_type;
    logic [2:0] id_ex_memory_size;
    logic id_ex_memory_unsigned;
    logic [4:0] id_ex_alu_operation;
    logic [2:0] id_ex_writeback_source;
    logic id_ex_reg_write;
    logic id_ex_mem_read;
    logic id_ex_mem_write;
    logic id_ex_alu_src_imm;
    logic id_ex_branch;
    logic id_ex_jump;
    logic id_ex_jump_register;

    logic ex_mem_valid;
    logic [63:0] ex_mem_alu_result;
    logic [63:0] ex_mem_store_data;
    logic [63:0] ex_mem_immediate;
    logic [63:0] ex_mem_pc4;
    logic [4:0] ex_mem_rd;
    logic [2:0] ex_mem_memory_size;
    logic ex_mem_memory_unsigned;
    logic [2:0] ex_mem_writeback_source;
    logic ex_mem_reg_write;
    logic ex_mem_mem_read;
    logic ex_mem_mem_write;

    logic mem_wb_valid;
    logic [63:0] mem_wb_alu_result;
    logic [63:0] mem_wb_load_data;
    logic [63:0] mem_wb_immediate;
    logic [63:0] mem_wb_pc4;
    logic [2:0] mem_wb_address;
    logic [4:0] mem_wb_rd;
    logic [2:0] mem_wb_memory_size;
    logic mem_wb_memory_unsigned;
    logic [2:0] mem_wb_writeback_source;
    logic mem_wb_reg_write;

    logic id_valid, id_reg_write;
    logic id_mem_read;
    logic id_mem_write;
    logic id_alu_src_imm;
    logic id_branch;
    logic id_jump, id_jump_register;
    logic [2:0] id_branch_type, id_memory_size;
    logic id_memory_unsigned;
    logic [4:0] id_alu_operation; logic [2:0] id_writeback_source;
    logic [63:0] id_immediate;
    logic [63:0] id_register_a, id_register_b;
    logic [63:0] register_read_a, register_read_b;
    logic [63:0] writeback_data;

    logic stall;
    logic [63:0] ex_register_b, ex_alu_result;
    logic ex_control_taken;
    logic [63:0] ex_target_pc;

    decoder instruction_decoder (
        .instruction(if_id_instruction),
        .valid(id_valid),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .alu_src_imm(id_alu_src_imm),
        .branch(id_branch),
        .jump(id_jump),
        .jump_register(id_jump_register),
        .branch_type(id_branch_type),
        .memory_size(id_memory_size),
        .memory_unsigned(id_memory_unsigned),
        .alu_operation(id_alu_operation),
        .writeback_source(id_writeback_source),
        .immediate(id_immediate)
    );

    regfile register_file (
        .clk(clk_i),
        .reset(reset_i),
        .write_enable(mem_wb_valid && mem_wb_reg_write),
        .write_address(mem_wb_rd),
        .write_data(writeback_data),
        .read_address_a(if_id_instruction[19:15]),
        .read_address_b(if_id_instruction[24:20]),
        .read_data_a(register_read_a),
        .read_data_b(register_read_b),
        .debug_x10(debug_x10_o),
        .debug_x31(debug_x31_o)
    );

    pipeline_writeback writeback_stage (
        .source_i(mem_wb_writeback_source),
        .alu_result_i(mem_wb_alu_result),
        .load_data_i(mem_wb_load_data),
        .immediate_i(mem_wb_immediate),
        .pc4_i(mem_wb_pc4),
        .memory_size_i(mem_wb_memory_size),
        .memory_unsigned_i(mem_wb_memory_unsigned),
        .address_offset_i(mem_wb_address),
        .data_o(writeback_data)
    );

    always_comb begin
        id_register_a = register_read_a;
        id_register_b = register_read_b;
        if (mem_wb_valid && mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == if_id_instruction[19:15])) begin
            id_register_a = writeback_data;
        end
        if (mem_wb_valid && mem_wb_reg_write && (mem_wb_rd != 5'd0) && (mem_wb_rd == if_id_instruction[24:20])) begin
            id_register_b = writeback_data;
        end
    end

    pipeline_hazard hazard_unit (
        .if_valid_i(if_id_valid),
        .if_opcode_i(if_id_instruction[6:0]),
        .if_rs1_i(if_id_instruction[19:15]),
        .if_rs2_i(if_id_instruction[24:20]),
        .id_ex_valid_i(id_ex_valid),
        .id_ex_mem_read_i(id_ex_mem_read),
        .id_ex_rd_i(id_ex_rd),
        .stall_o(stall)
    );

    pipeline_execute execute_stage (
        .id_valid_i(id_ex_valid),
        .id_pc_i(id_ex_pc),
        .id_register_a_i(id_ex_register_a),
        .id_register_b_i(id_ex_register_b),
        .id_immediate_i(id_ex_immediate),
        .id_rs1_i(id_ex_rs1),
        .id_rs2_i(id_ex_rs2),
        .id_alu_operation_i(id_ex_alu_operation),
        .id_writeback_source_i(id_ex_writeback_source),
        .id_branch_type_i(id_ex_branch_type),
        .id_alu_src_imm_i(id_ex_alu_src_imm),
        .id_branch_i(id_ex_branch),
        .id_jump_i(id_ex_jump),
        .id_jump_register_i(id_ex_jump_register),
        .ex_valid_i(ex_mem_valid),
        .ex_reg_write_i(ex_mem_reg_write),
        .ex_mem_read_i(ex_mem_mem_read),
        .ex_rd_i(ex_mem_rd),
        .ex_result_i(ex_mem_alu_result),
        .wb_valid_i(mem_wb_valid),
        .wb_reg_write_i(mem_wb_reg_write),
        .wb_rd_i(mem_wb_rd),
        .wb_data_i(writeback_data),
        .result_b_o(ex_register_b),
        .alu_result_o(ex_alu_result),
        .control_taken_o(ex_control_taken),
        .target_pc_o(ex_target_pc)
    );

    pipeline_memory_port memory_port (
        .valid_i(ex_mem_valid),
        .read_enable_i(ex_mem_mem_read),
        .write_enable_i(ex_mem_mem_write),
        .address_i(ex_mem_alu_result),
        .store_data_i(ex_mem_store_data),
        .memory_size_i(ex_mem_memory_size),
        .data_address_o(data_address_o),
        .data_read_enable_o(data_read_enable_o),
        .data_write_data_o(data_write_data_o),
        .data_write_mask_o(data_write_mask_o),
        .data_write_enable_o(data_write_enable_o)
    );

    assign illegal_instruction_o = if_id_valid && !id_valid;

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            pc_o <= 64'd0;
            if_id_valid <= 1'b0;
            id_ex_valid <= 1'b0;
            ex_mem_valid <= 1'b0;
            mem_wb_valid <= 1'b0;
        end else begin
            mem_wb_valid <= ex_mem_valid;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_load_data <= data_read_data_i;
            mem_wb_immediate <= ex_mem_immediate;
            mem_wb_pc4 <= ex_mem_pc4;
            mem_wb_address <= ex_mem_alu_result[2:0];
            mem_wb_rd <= ex_mem_rd;
            mem_wb_memory_size <= ex_mem_memory_size;
            mem_wb_memory_unsigned <= ex_mem_memory_unsigned;
            mem_wb_writeback_source <= ex_mem_writeback_source;
            mem_wb_reg_write <= ex_mem_reg_write;

            ex_mem_valid <= id_ex_valid;
            ex_mem_alu_result <= ex_alu_result;
            ex_mem_store_data <= ex_register_b;
            ex_mem_immediate <= id_ex_immediate;
            ex_mem_pc4 <= id_ex_pc + 64'd4;
            ex_mem_rd <= id_ex_rd;
            ex_mem_memory_size <= id_ex_memory_size;
            ex_mem_memory_unsigned <= id_ex_memory_unsigned;
            ex_mem_writeback_source <= id_ex_writeback_source;
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_mem_read <= id_ex_mem_read;
            ex_mem_mem_write <= id_ex_mem_write;

            if (ex_control_taken) begin
                pc_o <= ex_target_pc;
                if_id_valid <= 1'b0;
                id_ex_valid <= 1'b0;
            end else if (stall) begin
                pc_o <= pc_o;
                if_id_valid <= if_id_valid;
                id_ex_valid <= 1'b0;
            end else begin
                pc_o <= pc_o + 64'd4;
                if_id_valid <= 1'b1;
                if_id_pc <= pc_o;
                if_id_instruction <= instruction_i;

                id_ex_valid <= if_id_valid && id_valid;
                id_ex_pc <= if_id_pc;
                id_ex_register_a <= id_register_a;
                id_ex_register_b <= id_register_b;
                id_ex_immediate <= id_immediate;
                id_ex_rs1 <= if_id_instruction[19:15];
                id_ex_rs2 <= if_id_instruction[24:20];
                id_ex_rd <= if_id_instruction[11:7];
                id_ex_branch_type <= id_branch_type;
                id_ex_memory_size <= id_memory_size;
                id_ex_memory_unsigned <= id_memory_unsigned;
                id_ex_alu_operation <= id_alu_operation;
                id_ex_writeback_source <= id_writeback_source;
                id_ex_reg_write <= id_reg_write;
                id_ex_mem_read <= id_mem_read;
                id_ex_mem_write <= id_mem_write;
                id_ex_alu_src_imm <= id_alu_src_imm;
                id_ex_branch <= id_branch;
                id_ex_jump <= id_jump;
                id_ex_jump_register <= id_jump_register;
            end
        end
    end

endmodule
