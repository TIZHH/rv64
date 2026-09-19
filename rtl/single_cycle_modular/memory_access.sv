module memory_access (
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [2:0]  memory_size,
    input  logic        memory_unsigned,
    input  logic [2:0]  byte_offset,
    input  logic [63:0] store_value,
    input  logic [63:0] read_data,
    output logic [63:0] load_value,
    output logic [63:0] write_data,
    output logic [7:0]  write_mask,
    output logic        read_enable,
    output logic        write_enable
);

    logic [63:0] shifted_read_data;

    always_comb begin
        read_enable = mem_read;
        write_enable = mem_write;
        write_data = store_value << (byte_offset * 8);
        write_mask = 8'd0;

        if (mem_write) begin
            case (memory_size)
                3'd0: write_mask = 8'b00000001 << byte_offset;
                3'd1: write_mask = 8'b00000011 << byte_offset;
                3'd2: write_mask = 8'b00001111 << byte_offset;
                3'd3: write_mask = 8'b11111111;
                default: write_mask = 8'd0;
            endcase
        end

        shifted_read_data = read_data >> (byte_offset * 8);
        case (memory_size)
            3'd0: load_value = memory_unsigned
                ? {56'd0, shifted_read_data[7:0]}
                : {{56{shifted_read_data[7]}}, shifted_read_data[7:0]};
            3'd1: load_value = memory_unsigned
                ? {48'd0, shifted_read_data[15:0]}
                : {{48{shifted_read_data[15]}}, shifted_read_data[15:0]};
            3'd2: load_value = memory_unsigned
                ? {32'd0, shifted_read_data[31:0]}
                : {{32{shifted_read_data[31]}}, shifted_read_data[31:0]};
            default: load_value = shifted_read_data;
        endcase
    end

endmodule
