module single_cycle_cpu (
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
    logic [63:0] writeback_data;
    logic [63:0] next_pc;
    logic [63:0] load_value;
    logic [63:0] load_writeback;
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

    always_comb begin
        data_address = alu_result;
        data_write_data = register_b << (data_address[2:0] * 8);
        data_write_mask = 8'd0;
        data_write_enable = mem_write && valid;
        if (mem_write && valid) begin
            case (memory_size)
                3'd0: data_write_mask = 8'b00000001 << data_address[2:0];
                3'd1: data_write_mask = 8'b00000011 << data_address[2:0];
                3'd2: data_write_mask = 8'b00001111 << data_address[2:0];
                3'd3: data_write_mask = 8'b11111111;
                default: data_write_mask = 8'd0;
            endcase
        end

        load_value = data_read_data >> (data_address[2:0] * 8);
        if (memory_size == 3'd0) begin
            load_writeback = memory_unsigned ? {56'd0, load_value[7:0]} : {{56{load_value[7]}}, load_value[7:0]};
        end else if (memory_size == 3'd1) begin
            load_writeback = memory_unsigned ? {48'd0, load_value[15:0]} : {{48{load_value[15]}}, load_value[15:0]};
        end else if (memory_size == 3'd2) begin
            load_writeback = memory_unsigned ? {32'd0, load_value[31:0]} : {{32{load_value[31]}}, load_value[31:0]};
        end else begin
            load_writeback = load_value;
        end

        case (writeback_source)
            3'd0: writeback_data = alu_result;
            3'd1: writeback_data = load_writeback;
            3'd2: writeback_data = pc + 64'd4;
            3'd3: writeback_data = immediate;
            3'd4: writeback_data = pc + immediate;
            default: writeback_data = alu_result;
        endcase

        branch_taken = 1'b0;
        case (branch_type)
            3'b000: branch_taken = register_a == register_b;
            3'b001: branch_taken = register_a != register_b;
            3'b100: branch_taken = $signed(register_a) < $signed(register_b);
            3'b101: branch_taken = $signed(register_a) >= $signed(register_b);
            3'b110: branch_taken = register_a < register_b;
            3'b111: branch_taken = register_a >= register_b;
            default: branch_taken = 1'b0;
        endcase

        next_pc = pc + 64'd4;
        if (branch && branch_taken) begin
            next_pc = pc + immediate;
        end
        if (jump) begin
            if (jump_register) begin
                next_pc = (register_a + immediate) & ~64'd1;
            end else begin
                next_pc = pc + immediate;
            end
        end
    end

    assign illegal_instruction = !valid;
    assign data_read_enable = mem_read && valid;

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 64'd0;
        end else begin
            pc <= next_pc;
        end
    end

endmodule
