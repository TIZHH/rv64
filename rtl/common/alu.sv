module alu (
    input  logic [4:0]  operation,
    input  logic [63:0] left,
    input  logic [63:0] right,
    output logic [63:0] result
);

    logic [31:0] word_result;

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

    always_comb begin
        word_result = 32'd0;
        case (operation)
            ALU_ADD:  result = left + right;
            ALU_SUB:  result = left - right;
            ALU_SLL:  result = left << right[5:0];
            ALU_SLT:  result = ($signed(left) < $signed(right)) ? 64'd1 : 64'd0;
            ALU_SLTU: result = (left < right) ? 64'd1 : 64'd0;
            ALU_XOR:  result = left ^ right;
            ALU_SRL:  result = left >> right[5:0];
            ALU_SRA:  result = $signed(left) >>> right[5:0];
            ALU_OR:   result = left | right;
            ALU_AND:  result = left & right;
            ALU_ADDW: begin
                word_result = left[31:0] + right[31:0];
                result = {{32{word_result[31]}}, word_result};
            end
            ALU_SUBW: begin
                word_result = left[31:0] - right[31:0];
                result = {{32{word_result[31]}}, word_result};
            end
            ALU_SLLW: begin
                word_result = left[31:0] << right[4:0];
                result = {{32{word_result[31]}}, word_result};
            end
            ALU_SRLW: begin
                word_result = left[31:0] >> right[4:0];
                result = {{32{word_result[31]}}, word_result};
            end
            ALU_SRAW: begin
                word_result = $signed(left[31:0]) >>> right[4:0];
                result = {{32{word_result[31]}}, word_result};
            end
            default:  result = 64'd0;
        endcase
    end

endmodule
