module pipeline_execute (
    input  logic        id_valid,
    input  logic [63:0] id_pc,
    input  logic [63:0] id_register_a,
    input  logic [63:0] id_register_b,
    input  logic [63:0] id_immediate,
    input  logic [4:0]  id_rs1,
    input  logic [4:0]  id_rs2,
    input  logic [4:0]  id_alu_operation,
    input  logic [2:0]  id_writeback_source,
    input  logic [2:0]  id_branch_type,
    input  logic        id_alu_src_imm,
    input  logic        id_branch,
    input  logic        id_jump,
    input  logic        id_jump_register,
    input  logic        ex_valid,
    input  logic        ex_reg_write,
    input  logic        ex_mem_read,
    input  logic [4:0]  ex_rd,
    input  logic [63:0] ex_result,
    input  logic        wb_valid,
    input  logic        wb_reg_write,
    input  logic [4:0]  wb_rd,
    input  logic [63:0] wb_data,
    output logic [63:0] result_b,
    output logic [63:0] alu_result,
    output logic        control_taken,
    output logic [63:0] target_pc
);

    logic [63:0] alu_right;
    logic [63:0] result_a;
    logic branch_taken;

    always_comb begin
        result_a = id_register_a;
        result_b = id_register_b;
        if (ex_valid && ex_reg_write && !ex_mem_read && (ex_rd != 5'd0) && (ex_rd == id_rs1)) begin
            result_a = ex_result;
        end else if (wb_valid && wb_reg_write && (wb_rd != 5'd0) && (wb_rd == id_rs1)) begin
            result_a = wb_data;
        end
        if (ex_valid && ex_reg_write && !ex_mem_read && (ex_rd != 5'd0) && (ex_rd == id_rs2)) begin
            result_b = ex_result;
        end else if (wb_valid && wb_reg_write && (wb_rd != 5'd0) && (wb_rd == id_rs2)) begin
            result_b = wb_data;
        end
        alu_right = id_alu_src_imm ? id_immediate : result_b;
        case (id_branch_type)
            3'b000: branch_taken = result_a == result_b;
            3'b001: branch_taken = result_a != result_b;
            3'b100: branch_taken = $signed(result_a) < $signed(result_b);
            3'b101: branch_taken = $signed(result_a) >= $signed(result_b);
            3'b110: branch_taken = result_a < result_b;
            3'b111: branch_taken = result_a >= result_b;
            default: branch_taken = 1'b0;
        endcase
        control_taken = id_valid && (id_jump || (id_branch && branch_taken));
        target_pc = id_jump_register ? ((result_a + id_immediate) & ~64'd1) : id_pc + id_immediate;
    end

    logic [63:0] id_result_left;

    alu execute_alu (
        .operation(id_alu_operation),
        .left(id_result_left),
        .right(alu_right),
        .result(alu_result)
    );

    always_comb begin
        id_result_left = id_writeback_source == 3'd4 ? id_pc : result_a;
    end

endmodule
