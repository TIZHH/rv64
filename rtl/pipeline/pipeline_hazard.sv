module pipeline_hazard (
    input  logic        if_valid,
    input  logic [6:0]  if_opcode,
    input  logic [4:0]  if_rs1,
    input  logic [4:0]  if_rs2,
    input  logic        id_ex_valid,
    input  logic        id_ex_mem_read,
    input  logic [4:0]  id_ex_rd,
    output logic        stall
);

    localparam logic [6:0] OP_LOAD = 7'b0000011;
    localparam logic [6:0] OP_IMM = 7'b0010011;
    localparam logic [6:0] OP_STORE = 7'b0100011;
    localparam logic [6:0] OP_REG = 7'b0110011;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JALR = 7'b1100111;
    localparam logic [6:0] OP_IMMW = 7'b0011011;
    localparam logic [6:0] OP_REGW = 7'b0111011;
    logic uses_rs1;
    logic uses_rs2;

    always_comb begin
        uses_rs1 = 1'b0;
        uses_rs2 = 1'b0;
        case (if_opcode)
            OP_REG, OP_REGW, OP_BRANCH, OP_STORE: begin
                uses_rs1 = 1'b1;
                uses_rs2 = 1'b1;
            end
            OP_IMM, OP_IMMW, OP_LOAD, OP_JALR: uses_rs1 = 1'b1;
            default: begin end
        endcase
        stall = if_valid && id_ex_valid && id_ex_mem_read && (id_ex_rd != 5'd0) &&
                ((uses_rs1 && (if_rs1 == id_ex_rd)) ||
                 (uses_rs2 && (if_rs2 == id_ex_rd)));
    end

endmodule
