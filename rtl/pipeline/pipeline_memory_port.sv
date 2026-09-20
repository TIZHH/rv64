module pipeline_memory_port (
    input  logic        valid_i,
    input  logic        read_enable_i,
    input  logic        write_enable_i,
    input  logic [63:0] address_i,
    input  logic [63:0] store_data_i,
    input  logic [2:0]  memory_size_i,
    output logic [63:0] data_address_o,
    output logic        data_read_enable_o,
    output logic [63:0] data_write_data_o,
    output logic [7:0]  data_write_mask_o,
    output logic        data_write_enable_o
);

    always_comb begin
        data_address_o = address_i;
        data_read_enable_o = valid_i && read_enable_i;
        data_write_enable_o = valid_i && write_enable_i;
        data_write_data_o = store_data_i << (address_i[2:0] * 8);
        data_write_mask_o = 8'd0;
        if (data_write_enable_o) begin
            case (memory_size_i)
                3'd0: data_write_mask_o = 8'b00000001 << address_i[2:0];
                3'd1: data_write_mask_o = 8'b00000011 << address_i[2:0];
                3'd2: data_write_mask_o = 8'b00001111 << address_i[2:0];
                3'd3: data_write_mask_o = 8'b11111111;
                default: data_write_mask_o = 8'd0;
            endcase
        end
    end

endmodule
