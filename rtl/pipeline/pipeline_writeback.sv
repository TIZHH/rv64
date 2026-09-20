module pipeline_writeback (
    input  logic [2:0]  source_i,
    input  logic [63:0] alu_result_i,
    input  logic [63:0] load_data_i,
    input  logic [63:0] immediate_i,
    input  logic [63:0] pc4_i,
    input  logic [2:0]  memory_size_i,
    input  logic        memory_unsigned_i,
    input  logic [2:0]  address_offset_i,
    output logic [63:0] data_o
);

    logic [63:0] load_value;

    always_comb begin
        load_value = load_data_i >> (address_offset_i * 8);
        if (memory_size_i == 3'd0) begin
            load_value = memory_unsigned_i ? {56'd0, load_value[7:0]} : {{56{load_value[7]}}, load_value[7:0]};
        end else if (memory_size_i == 3'd1) begin
            load_value = memory_unsigned_i ? {48'd0, load_value[15:0]} : {{48{load_value[15]}}, load_value[15:0]};
        end else if (memory_size_i == 3'd2) begin
            load_value = memory_unsigned_i ? {32'd0, load_value[31:0]} : {{32{load_value[31]}}, load_value[31:0]};
        end

        case (source_i)
            3'd0: data_o = alu_result_i;
            3'd1: data_o = load_value;
            3'd2: data_o = pc4_i;
            3'd3: data_o = immediate_i;
            3'd4: data_o = immediate_i + pc4_i - 64'd4;
            default: data_o = alu_result_i;
        endcase
    end

endmodule
