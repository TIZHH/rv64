module pc_register (
    input  logic        clk,
    input  logic        reset,
    input  logic [63:0] next_pc,
    output logic [63:0] pc
);

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 64'd0;
        end else begin
            pc <= next_pc;
        end
    end

endmodule
