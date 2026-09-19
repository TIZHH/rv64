module instruction_memory #(
    parameter integer WORDS = 256,
    parameter string  IMAGE_FILE = "sim/images/instruction.hex"
) (
    input  logic [63:0] address_i,
    output logic [31:0] instruction_o
);

    logic [31:0] storage [0:WORDS-1];
    integer index;
    integer reset_index;

    initial begin
        for (reset_index = 0; reset_index < WORDS; reset_index = reset_index + 1) begin
            storage[reset_index] = 32'd0;
        end
        $readmemh(IMAGE_FILE, storage);
    end

    always_comb begin
        index = int'(address_i >> 2);
        if (index < WORDS) begin
            instruction_o = storage[index];
        end else begin
            instruction_o = 32'd0;
        end
    end

endmodule
