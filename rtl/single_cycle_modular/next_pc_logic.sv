module next_pc_logic (
    input  logic [63:0] pc_i,
    input  logic [63:0] immediate_i,
    input  logic [63:0] register_a_i,
    input  logic        branch_i,
    input  logic        branch_taken_i,
    input  logic        jump_i,
    input  logic        jump_register_i,
    output logic [63:0] next_pc_o
);

    always_comb begin
        if (jump_i) begin
            if (jump_register_i) begin
                next_pc_o =
                    (register_a_i + immediate_i) & ~64'd1;
            end else begin
                next_pc_o = pc_i + immediate_i;
            end
        end else if (branch_i && branch_taken_i) begin
            next_pc_o = pc_i + immediate_i;
        end else begin
            next_pc_o = pc_i + 64'd4;
        end
    end

endmodule
