
module pipeline_execute (
    // 当前正在 EX 阶段的指令信息，来自 ID/EX 流水线寄存器
    input  logic        id_valid_i,
    input  logic [63:0] id_pc_i,
    input  logic [63:0] id_register_a_i,   // rs1 的值
    input  logic [63:0] id_register_b_i,   // rs2 的值
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

    // 前一条指令的结果，用来做 forwarding
    input  logic        ex_valid_i,
    input  logic        ex_reg_write_i,
    input  logic        ex_mem_read_i,
    input  logic [4:0]  ex_rd_i,
    input  logic [63:0] ex_result_i,

    // 更前面一条已经到 WB 的指令，也可以 forwarding
    input  logic        wb_valid_i,
    input  logic        wb_reg_write_i,
    input  logic [4:0]  wb_rd_i,
    input  logic [63:0] wb_data_i,

    // EX 阶段输出
    output logic [63:0] result_b_o,       // forwarding 后的 rs2
    output logic [63:0] alu_result_o,     // ALU 结果
    output logic        control_taken_o,  // 是否跳转
    output logic [63:0] target_pc_o       // 跳转目标地址
);

    logic [63:0] alu_right;
    logic [63:0] result_a;
    logic        branch_taken;

    always_comb begin
        // 默认直接使用 regfile 读出来的 rs1 / rs2
        result_a   = id_register_a_i;
        result_b_o = id_register_b_i;

        // =====================================================
        // rs1 forwarding
        // =====================================================

        // 优先使用前一条指令刚算出来的结果
        if (ex_valid_i &&
            ex_reg_write_i &&
            !ex_mem_read_i &&
            (ex_rd_i != 5'd0) &&
            (ex_rd_i == id_rs1_i)) begin

            result_a = ex_result_i;

        // 否则尝试使用 WB 阶段的数据
        end else if (wb_valid_i &&
                     wb_reg_write_i &&
                     (wb_rd_i != 5'd0) &&
                     (wb_rd_i == id_rs1_i)) begin

            result_a = wb_data_i;
        end


        // =====================================================
        // rs2 forwarding
        // =====================================================

        if (ex_valid_i &&
            ex_reg_write_i &&
            !ex_mem_read_i &&
            (ex_rd_i != 5'd0) &&
            (ex_rd_i == id_rs2_i)) begin

            result_b_o = ex_result_i;

        end else if (wb_valid_i &&
                     wb_reg_write_i &&
                     (wb_rd_i != 5'd0) &&
                     (wb_rd_i == id_rs2_i)) begin

            result_b_o = wb_data_i;
        end


        // =====================================================
        // ALU 右操作数选择
        // =====================================================
        // R-Type  : rs2
        // I-Type  : immediate
        alu_right =
            id_alu_src_imm_i ? id_immediate_i : result_b_o;


        // =====================================================
        // Branch 判断
        // =====================================================
        case (id_branch_type_i)
            3'b000: branch_taken = result_a == result_b_o;                  // BEQ
            3'b001: branch_taken = result_a != result_b_o;                  // BNE
            3'b100: branch_taken = $signed(result_a) < $signed(result_b_o); // BLT
            3'b101: branch_taken = $signed(result_a) >= $signed(result_b_o);// BGE
            3'b110: branch_taken = result_a < result_b_o;                   // BLTU
            3'b111: branch_taken = result_a >= result_b_o;                  // BGEU
            default: branch_taken = 1'b0;
        endcase


        // JAL/JALR 一定跳
        // Branch 只有条件成立才跳
        control_taken_o =
            id_valid_i &&
            (id_jump_i || (id_branch_i && branch_taken));


        // JALR:
        //   target = (rs1 + imm) & ~1
        //
        // JAL / Branch:
        //   target = pc + imm
        target_pc_o =
            id_jump_register_i
                ? ((result_a + id_immediate_i) & ~64'd1)
                : (id_pc_i + id_immediate_i);
    end


    logic [63:0] id_result_left;

    // 真正执行算术/逻辑运算的 ALU
    alu execute_alu (
        .operation(id_alu_operation_i),
        .left(id_result_left),
        .right(alu_right),
        .result(alu_result_o)
    );


    always_comb begin
        // 普通指令：
        //   ALU left = rs1
        //
        // AUIPC：
        //   ALU left = PC
        //
        // writeback_source == 4 表示 AUIPC
        id_result_left =
            (id_writeback_source_i == 3'd4)
                ? id_pc_i
                : result_a;
    end

endmodule
