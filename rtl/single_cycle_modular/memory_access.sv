module memory_access (
    input  logic        mem_read_i,
    input  logic        mem_write_i,
    input  logic [2:0]  memory_size_i,
    input  logic        memory_unsigned_i,
    input  logic [2:0]  byte_offset_i,
    input  logic [63:0] store_value_i,
    input  logic [63:0] read_data_i,
    output logic [63:0] load_value_o,
    output logic [63:0] write_data_o,
    output logic [7:0]  write_mask_o,
    output logic        read_enable_o,
    output logic        write_enable_o
);

    logic [63:0] shifted_read_data;

    always_comb begin
        read_enable_o = mem_read_i;
        write_enable_o = mem_write_i;
        write_data_o = store_value_i << (byte_offset_i * 8);
        write_mask_o = 8'd0;

        if (mem_write_i) begin
            case (memory_size_i)
                3'd0: write_mask_o = 8'b00000001 << byte_offset_i;
                3'd1: write_mask_o = 8'b00000011 << byte_offset_i;
                3'd2: write_mask_o = 8'b00001111 << byte_offset_i;
                3'd3: write_mask_o = 8'b11111111;
                default: write_mask_o = 8'd0;
            endcase
        end

        shifted_read_data = read_data_i >> (byte_offset_i * 8);
        case (memory_size_i)
            3'd0: load_value_o = memory_unsigned_i
                ? {56'd0, shifted_read_data[7:0]}
                : {{56{shifted_read_data[7]}}, shifted_read_data[7:0]};
            3'd1: load_value_o = memory_unsigned_i
                ? {48'd0, shifted_read_data[15:0]}
                : {{48{shifted_read_data[15]}}, shifted_read_data[15:0]};
            3'd2: load_value_o = memory_unsigned_i
                ? {32'd0, shifted_read_data[31:0]}
                : {{32{shifted_read_data[31]}}, shifted_read_data[31:0]};
            default: load_value_o = shifted_read_data;
        endcase
    end

endmodule
