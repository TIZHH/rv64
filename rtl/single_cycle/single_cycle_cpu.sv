module single_cycle_cpu (
    input  logic        clk,
    input  logic        reset,
    output logic [63:0] pc
);

    always_ff @(posedge clk) begin
        if (reset) begin
            pc <= 64'd0;
        end else begin
            pc <= pc + 64'd4;
        end
    end

endmodule
