module pipeline_execute (
    input  logic        id_valid_i,
    input  logic [63:0] id_pc_i,
    input  logic [63:0] id_register_a_i,
    input  logic [63:0] id_register_b_i,
    input  logic [63:0] id_immediate_i,
    input  logic [4:0]  id_rs1_i,
    input  logic [4:0]  id_rs2_i,
    input  logic [4:0]  id_alu_operation_i,
    input  logic [2:0]  id_writeback_source_i,
    input  logic [2:0]  id_branch_type_i,
    input  logic        id_alu_src_imm_i,
    input  logic        id_branch_i,
    input  logic        id_jump_i,
    input  logic        id_jump_register_i,
    input  logic        ex_valid_i,
    input  logic        ex_reg_write_i,
    input  logic        ex_mem_read_i,
    input  logic [4:0]  ex_rd_i,
    input  logic [63:0] ex_result_i,
    input  logic        wb_valid_i,
    input  logic        wb_reg_write_i,
    input  logic [4:0]  wb_rd_i,
    input  logic [63:0] wb_data_i,
    output logic [63:0] result_b_o,
    output logic [63:0] alu_result_o,
    output logic        control_taken_o,
    output logic [63:0] target_pc_o
);

    logic [63:0] alu_right;
    logic [63:0] result_a;
    logic branch_taken;

    always_comb begin
        result_a = id_register_a_i;
        result_b_o = id_register_b_i;
        if (ex_valid_i && ex_reg_write_i && !ex_mem_read_i && (ex_rd_i != 5'd0) && (ex_rd_i == id_rs1_i)) begin
            result_a = ex_result_i;
        end else if (wb_valid_i && wb_reg_write_i && (wb_rd_i != 5'd0) && (wb_rd_i == id_rs1_i)) begin
            result_a = wb_data_i;
        end
        if (ex_valid_i && ex_reg_write_i && !ex_mem_read_i && (ex_rd_i != 5'd0) && (ex_rd_i == id_rs2_i)) begin
            result_b_o = ex_result_i;
        end else if (wb_valid_i && wb_reg_write_i && (wb_rd_i != 5'd0) && (wb_rd_i == id_rs2_i)) begin
            result_b_o = wb_data_i;
        end
        alu_right = id_alu_src_imm_i ? id_immediate_i : result_b_o;
        case (id_branch_type_i)
            3'b000: branch_taken = result_a == result_b_o;
            3'b001: branch_taken = result_a != result_b_o;
            3'b100: branch_taken = $signed(result_a) < $signed(result_b_o);
            3'b101: branch_taken = $signed(result_a) >= $signed(result_b_o);
            3'b110: branch_taken = result_a < result_b_o;
            3'b111: branch_taken = result_a >= result_b_o;
            default: branch_taken = 1'b0;
        endcase
        control_taken_o = id_valid_i && (id_jump_i || (id_branch_i && branch_taken));
        target_pc_o = id_jump_register_i ? ((result_a + id_immediate_i) & ~64'd1) : id_pc_i + id_immediate_i;
    end

    logic [63:0] id_result_left;

    alu execute_alu (
        .operation(id_alu_operation_i),
        .left(id_result_left),
        .right(alu_right),
        .result(alu_result_o)
    );

    always_comb begin
        id_result_left = id_writeback_source_i == 3'd4 ? id_pc_i : result_a;
    end

endmodule
