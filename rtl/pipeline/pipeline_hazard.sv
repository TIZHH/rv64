
module pipeline_hazard (
    // 当前 IF/ID 阶段里的指令是否有效
    input  logic        if_valid_i,

    // 当前这条指令的 opcode
    input  logic [6:0]  if_opcode_i,

    // 当前这条指令使用的 rs1 / rs2
    input  logic [4:0]  if_rs1_i,
    input  logic [4:0]  if_rs2_i,

    // 当前 EX 阶段里的上一条指令信息
    input  logic        id_ex_valid_i,

    // 上一条指令是不是 Load
    input  logic        id_ex_mem_read_i,

    // 上一条 Load 要写回哪个寄存器
    input  logic [4:0]  id_ex_rd_i,

    // 是否需要让流水线暂停一拍
    output logic        stall_o
);

    // 一些会用到的 opcode
    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_IMM    = 7'b0010011;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_REG    = 7'b0110011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_IMMW   = 7'b0011011;
    localparam logic [6:0] OP_REGW   = 7'b0111011;

    // 当前指令是否真的会使用 rs1 / rs2
    logic uses_rs1;
    logic uses_rs2;

    always_comb begin
        // 默认认为不使用 rs1 / rs2
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;

        // 根据 opcode 判断当前指令会使用哪些源寄存器
        case (if_opcode_i)

            // R-Type / R-Type-W / Branch / Store
            // 都需要 rs1 和 rs2
            OP_REG,
            OP_REGW,
            OP_BRANCH,
            OP_STORE: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end

            // I-Type / I-Type-W / Load / JALR
            // 只需要 rs1
            OP_IMM,
            OP_IMMW,
            OP_LOAD,
            OP_JALR: begin
                uses_rs1 = 1'b1;
            end

            // 例如 LUI / AUIPC / JAL
            // 不需要 rs1 / rs2
            default: begin
            end
        endcase


        // 如果：
        // 1. 当前指令有效
        // 2. 上一条指令有效
        // 3. 上一条指令是 Load
        // 4. Load 写入的不是 x0
        // 5. 当前指令马上要使用这个 rd
        //
        // 那么就必须 stall 一拍
        stall_o =
            if_valid_i &&
            id_ex_valid_i &&
            id_ex_mem_read_i &&
            (id_ex_rd_i != 5'd0) &&
            (
                (uses_rs1 && (if_rs1_i == id_ex_rd_i)) ||
                (uses_rs2 && (if_rs2_i == id_ex_rd_i))
            );
    end

endmodule
