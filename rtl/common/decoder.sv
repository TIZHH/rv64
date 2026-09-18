module decoder (
    input  logic [31:0] instruction,
    output logic        valid,
    output logic        reg_write,
    output logic        mem_read,
    output logic        mem_write,
    output logic        alu_src_imm,
    output logic        branch,
    output logic        jump,
    output logic        jump_register,
    output logic [2:0]  branch_type,
    output logic [2:0]  memory_size,
    output logic        memory_unsigned,
    output logic [4:0]  alu_operation,
    output logic [2:0]  writeback_source,
    output logic [63:0] immediate
);

    localparam logic [6:0] OP_LOAD   = 7'b0000011;
    localparam logic [6:0] OP_IMM    = 7'b0010011;
    localparam logic [6:0] OP_AUIPC  = 7'b0010111;
    localparam logic [6:0] OP_STORE  = 7'b0100011;
    localparam logic [6:0] OP_REG    = 7'b0110011;
    localparam logic [6:0] OP_LUI    = 7'b0110111;
    localparam logic [6:0] OP_BRANCH = 7'b1100011;
    localparam logic [6:0] OP_JALR   = 7'b1100111;
    localparam logic [6:0] OP_JAL    = 7'b1101111;
    localparam logic [6:0] OP_IMMW   = 7'b0011011;
    localparam logic [6:0] OP_REGW   = 7'b0111011;

    localparam logic [4:0] ALU_ADD  = 5'd0;
    localparam logic [4:0] ALU_SUB  = 5'd1;
    localparam logic [4:0] ALU_SLL  = 5'd2;
    localparam logic [4:0] ALU_SLT  = 5'd3;
    localparam logic [4:0] ALU_SLTU = 5'd4;
    localparam logic [4:0] ALU_XOR  = 5'd5;
    localparam logic [4:0] ALU_SRL  = 5'd6;
    localparam logic [4:0] ALU_SRA  = 5'd7;
    localparam logic [4:0] ALU_OR   = 5'd8;
    localparam logic [4:0] ALU_AND  = 5'd9;
    localparam logic [4:0] ALU_ADDW = 5'd10;
    localparam logic [4:0] ALU_SUBW = 5'd11;
    localparam logic [4:0] ALU_SLLW = 5'd12;
    localparam logic [4:0] ALU_SRLW = 5'd13;
    localparam logic [4:0] ALU_SRAW = 5'd14;

    localparam logic [2:0] WB_ALU = 3'd0;
    localparam logic [2:0] WB_LOAD = 3'd1;
    localparam logic [2:0] WB_PC4 = 3'd2;
    localparam logic [2:0] WB_IMM = 3'd3;
    localparam logic [2:0] WB_AUIPC = 3'd4;

    always_comb begin
        valid = 1'b0;
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        alu_src_imm = 1'b0;
        branch = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        branch_type = 3'd0;
        memory_size = 3'd0;
        memory_unsigned = 1'b0;
        alu_operation = ALU_ADD;
        writeback_source = WB_ALU;
        immediate = 64'd0;

        case (instruction[6:0])
            OP_REG, OP_REGW: begin
                if ((instruction[6:0] == OP_REG) && (instruction[31:25] == 7'b0000000 || instruction[31:25] == 7'b0100000)) begin
                    valid = 1'b1;
                    reg_write = 1'b1;
                    case (instruction[14:12])
                        3'b000: alu_operation = instruction[30] ? ALU_SUB : ALU_ADD;
                        3'b001: alu_operation = ALU_SLL;
                        3'b010: alu_operation = ALU_SLT;
                        3'b011: alu_operation = ALU_SLTU;
                        3'b100: alu_operation = ALU_XOR;
                        3'b101: alu_operation = instruction[30] ? ALU_SRA : ALU_SRL;
                        3'b110: alu_operation = ALU_OR;
                        3'b111: alu_operation = ALU_AND;
                        default: valid = 1'b0;
                    endcase
                end else if ((instruction[6:0] == OP_REGW) && (instruction[31:25] == 7'b0000000 || instruction[31:25] == 7'b0100000)) begin
                    valid = 1'b1;
                    reg_write = 1'b1;
                    case (instruction[14:12])
                        3'b000: alu_operation = instruction[30] ? ALU_SUBW : ALU_ADDW;
                        3'b001: alu_operation = ALU_SLLW;
                        3'b101: alu_operation = instruction[30] ? ALU_SRAW : ALU_SRLW;
                        default: valid = 1'b0;
                    endcase
                end
            end
            OP_IMM, OP_IMMW: begin
                if (instruction[6:0] == OP_IMM) begin
                    immediate = {{52{instruction[31]}}, instruction[31:20]};
                    valid = 1'b1;
                    reg_write = 1'b1;
                    alu_src_imm = 1'b1;
                    case (instruction[14:12])
                        3'b000: alu_operation = ALU_ADD;
                        3'b010: alu_operation = ALU_SLT;
                        3'b011: alu_operation = ALU_SLTU;
                        3'b100: alu_operation = ALU_XOR;
                        3'b110: alu_operation = ALU_OR;
                        3'b111: alu_operation = ALU_AND;
                        3'b001: begin
                            if (instruction[31:26] == 6'b000000) alu_operation = ALU_SLL;
                            else valid = 1'b0;
                        end
                        3'b101: begin
                            if (instruction[31:26] == 6'b000000) alu_operation = ALU_SRL;
                            else if (instruction[31:26] == 6'b010000) alu_operation = ALU_SRA;
                            else valid = 1'b0;
                        end
                        default: valid = 1'b0;
                    endcase
                end else begin
                    immediate = {{52{instruction[31]}}, instruction[31:20]};
                    valid = 1'b1;
                    reg_write = 1'b1;
                    alu_src_imm = 1'b1;
                    case (instruction[14:12])
                        3'b000: alu_operation = ALU_ADDW;
                        3'b001: begin
                            if (instruction[31:25] == 7'b0000000) alu_operation = ALU_SLLW;
                            else valid = 1'b0;
                        end
                        3'b101: begin
                            if (instruction[31:25] == 7'b0000000) alu_operation = ALU_SRLW;
                            else if (instruction[31:25] == 7'b0100000) alu_operation = ALU_SRAW;
                            else valid = 1'b0;
                        end
                        default: valid = 1'b0;
                    endcase
                end
            end
            OP_LUI, OP_AUIPC: begin
                valid = 1'b1;
                reg_write = 1'b1;
                alu_src_imm = 1'b1;
                immediate = {{32{instruction[31]}}, instruction[31:12], 12'd0};
                writeback_source = (instruction[6:0] == OP_LUI) ? WB_IMM : WB_AUIPC;
            end
            OP_LOAD: begin
                if (instruction[14:12] == 3'b000 || instruction[14:12] == 3'b001 || instruction[14:12] == 3'b010 || instruction[14:12] == 3'b011 || instruction[14:12] == 3'b100 || instruction[14:12] == 3'b101 || instruction[14:12] == 3'b110) begin
                    valid = 1'b1;
                    reg_write = 1'b1;
                    mem_read = 1'b1;
                    alu_src_imm = 1'b1;
                    alu_operation = ALU_ADD;
                    writeback_source = WB_LOAD;
                    immediate = {{52{instruction[31]}}, instruction[31:20]};
                    memory_size = instruction[14:12] == 3'b000 || instruction[14:12] == 3'b100 ? 3'd0 : instruction[14:12] == 3'b001 || instruction[14:12] == 3'b101 ? 3'd1 : instruction[14:12] == 3'b010 || instruction[14:12] == 3'b110 ? 3'd2 : 3'd3;
                    memory_unsigned = instruction[14];
                end
            end
            OP_STORE: begin
                if (instruction[14:12] == 3'b000 || instruction[14:12] == 3'b001 || instruction[14:12] == 3'b010 || instruction[14:12] == 3'b011) begin
                    valid = 1'b1;
                    mem_write = 1'b1;
                    alu_src_imm = 1'b1;
                    alu_operation = ALU_ADD;
                    immediate = {{52{instruction[31]}}, instruction[31:25], instruction[11:7]};
                    memory_size = instruction[14:12];
                end
            end
            OP_BRANCH: begin
                if (instruction[14:12] == 3'b000 || instruction[14:12] == 3'b001 || instruction[14:12] == 3'b100 || instruction[14:12] == 3'b101 || instruction[14:12] == 3'b110 || instruction[14:12] == 3'b111) begin
                    valid = 1'b1;
                    branch = 1'b1;
                    branch_type = instruction[14:12];
                    immediate = {{51{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
                end
            end
            OP_JAL: begin
                valid = 1'b1;
                reg_write = 1'b1;
                jump = 1'b1;
                writeback_source = WB_PC4;
                immediate = {{43{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end
            OP_JALR: begin
                if (instruction[14:12] == 3'b000) begin
                    valid = 1'b1;
                    reg_write = 1'b1;
                    jump = 1'b1;
                    jump_register = 1'b1;
                    alu_src_imm = 1'b1;
                    writeback_source = WB_PC4;
                    immediate = {{52{instruction[31]}}, instruction[31:20]};
                end
            end
            default: begin
                valid = 1'b0;
            end
        endcase
    end

endmodule
