module pipeline_writeback (
    input  logic [2:0]  source,
    input  logic [63:0] alu_result,
    input  logic [63:0] load_data,
    input  logic [63:0] immediate,
    input  logic [63:0] pc4,
    input  logic [2:0]  memory_size,
    input  logic        memory_unsigned,
    input  logic [2:0]  address_offset,
    output logic [63:0] data
);

    logic [63:0] load_value;

    always_comb begin
        load_value = load_data >> (address_offset * 8);
        if (memory_size == 3'd0) begin
            load_value = memory_unsigned ? {56'd0, load_value[7:0]} : {{56{load_value[7]}}, load_value[7:0]};
        end else if (memory_size == 3'd1) begin
            load_value = memory_unsigned ? {48'd0, load_value[15:0]} : {{48{load_value[15]}}, load_value[15:0]};
        end else if (memory_size == 3'd2) begin
            load_value = memory_unsigned ? {32'd0, load_value[31:0]} : {{32{load_value[31]}}, load_value[31:0]};
        end

        case (source)
            3'd0: data = alu_result;
            3'd1: data = load_value;
            3'd2: data = pc4;
            3'd3: data = immediate;
            3'd4: data = immediate + pc4 - 64'd4;
            default: data = alu_result;
        endcase
    end

endmodule
