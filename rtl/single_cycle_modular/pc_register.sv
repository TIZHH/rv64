module pc_register (
    input  logic        clk_i,
    input  logic        reset_i,
    input  logic [63:0] next_pc_i,
    output logic [63:0] pc_o
);

    always_ff @(posedge clk_i) begin
        if (reset_i) begin
            pc_o <= 64'd0;
        end else begin
            pc_o <= next_pc_i;
        end
    end

endmodule
