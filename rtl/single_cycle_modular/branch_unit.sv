module branch_unit (
    input  logic [2:0]  branch_type_i,
    input  logic [63:0] left_i,
    input  logic [63:0] right_i,
    output logic        taken_o
);

    always_comb begin
        case (branch_type_i)
            3'b000: taken_o = left_i == right_i;
            3'b001: taken_o = left_i != right_i;
            3'b100: taken_o = $signed(left_i) < $signed(right_i);
            3'b101: taken_o = $signed(left_i) >= $signed(right_i);
            3'b110: taken_o = left_i < right_i;
            3'b111: taken_o = left_i >= right_i;
            default: taken_o = 1'b0;
        endcase
    end

endmodule
