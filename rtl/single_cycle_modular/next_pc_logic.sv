module next_pc_logic (
    input  logic [63:0] pc,
    input  logic [63:0] immediate,
    input  logic [63:0] register_a,
    input  logic        branch,
    input  logic        branch_taken,
    input  logic        jump,
    input  logic        jump_register,
    output logic [63:0] next_pc
);

    always_comb begin
        next_pc = pc + 64'd4;

        if (branch && branch_taken) begin
            next_pc = pc + immediate;
        end

        if (jump) begin
            if (jump_register) begin
                next_pc = (register_a + immediate) & ~64'd1;
            end else begin
                next_pc = pc + immediate;
            end
        end
    end

endmodule
