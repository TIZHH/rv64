module pipeline_memory_port (
    input  logic        valid,
    input  logic        read_enable,
    input  logic        write_enable,
    input  logic [63:0] address,
    input  logic [63:0] store_data,
    input  logic [2:0]  memory_size,
    output logic [63:0] data_address,
    output logic        data_read_enable,
    output logic [63:0] data_write_data,
    output logic [7:0]  data_write_mask,
    output logic        data_write_enable
);

    always_comb begin
        data_address = address;
        data_read_enable = valid && read_enable;
        data_write_enable = valid && write_enable;
        data_write_data = store_data << (address[2:0] * 8);
        data_write_mask = 8'd0;
        if (data_write_enable) begin
            case (memory_size)
                3'd0: data_write_mask = 8'b00000001 << address[2:0];
                3'd1: data_write_mask = 8'b00000011 << address[2:0];
                3'd2: data_write_mask = 8'b00001111 << address[2:0];
                3'd3: data_write_mask = 8'b11111111;
                default: data_write_mask = 8'd0;
            endcase
        end
    end

endmodule
