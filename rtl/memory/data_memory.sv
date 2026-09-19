module data_memory #(
    parameter integer BYTES = 4096,
    parameter string  IMAGE_FILE = "sim/images/data.hex",
    parameter integer DEBUG_ADDRESS = 'h100
) (
    input  logic        clk,
    input  logic [63:0] address,
    input  logic        read_enable,
    output logic [63:0] read_data,
    input  logic [63:0] write_data,
    input  logic [7:0]  write_mask,
    input  logic        write_enable,
    output logic [63:0] debug_word
);

    logic [7:0] storage [0:BYTES-1];
    integer read_lane;
    integer write_lane;
    integer debug_lane;
    integer reset_index;
    integer read_base_address;
    integer write_base_address;

    initial begin
        for (reset_index = 0; reset_index < BYTES; reset_index = reset_index + 1) begin
            storage[reset_index] = 8'd0;
        end
        $readmemh(IMAGE_FILE, storage);
    end

    always_comb begin
        read_data = 64'd0;
        read_base_address = int'(address >> 3) * 8;
        write_base_address = int'(address >> 3) * 8;
        if (read_enable && (read_base_address >= 0) && (read_base_address + 7 < BYTES)) begin
            for (read_lane = 0; read_lane < 8; read_lane = read_lane + 1) begin
                read_data[read_lane * 8 +: 8] = storage[read_base_address + read_lane];
            end
        end
    end

    always_ff @(posedge clk) begin
        if (write_enable && (address[63:32] == 32'd0) &&
            (address[31:0] <= BYTES - 8)) begin
            for (write_lane = 0; write_lane < 8; write_lane = write_lane + 1) begin
                if (write_mask[write_lane]) begin
                    storage[write_base_address + write_lane] <= write_data[write_lane * 8 +: 8];
                end
            end
        end
    end

    always_comb begin
        debug_word = 64'd0;
        if ((DEBUG_ADDRESS >= 0) && (DEBUG_ADDRESS + 7 < BYTES)) begin
            for (debug_lane = 0; debug_lane < 8; debug_lane = debug_lane + 1) begin
                debug_word[debug_lane * 8 +: 8] = storage[DEBUG_ADDRESS + debug_lane];
            end
        end
    end

endmodule
