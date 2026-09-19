module branch_unit (
    input  logic [2:0]  branch_type,
    input  logic [63:0] left,
    input  logic [63:0] right,
    output logic        taken
);

    always_comb begin
        case (branch_type)
            3'b000: taken = left == right;
            3'b001: taken = left != right;
            3'b100: taken = $signed(left) < $signed(right);
            3'b101: taken = $signed(left) >= $signed(right);
            3'b110: taken = left < right;
            3'b111: taken = left >= right;
            default: taken = 1'b0;
        endcase
    end

endmodule
