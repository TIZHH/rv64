module regfile (
    input  logic        clk,
    input  logic        reset,
    input  logic        write_enable,
    input  logic [4:0]  write_address,
    input  logic [63:0] write_data,
    input  logic [4:0]  read_address_a,
    input  logic [4:0]  read_address_b,
    output logic [63:0] read_data_a,
    output logic [63:0] read_data_b,
    output logic [63:0] debug_x10,
    output logic [63:0] debug_x31
);

    logic [63:0] storage [0:31];
    integer index;

    always_ff @(posedge clk) begin
        if (reset) begin
            for (index = 0; index < 32; index = index + 1) begin
                storage[index] <= 64'd0;
            end
        end else if (write_enable && (write_address != 5'd0)) begin
            storage[write_address] <= write_data;
        end
    end

    always_comb begin
        if (read_address_a == 5'd0) begin
            read_data_a = 64'd0;
        end else begin
            read_data_a = storage[read_address_a];
        end

        if (read_address_b == 5'd0) begin
            read_data_b = 64'd0;
        end else begin
            read_data_b = storage[read_address_b];
        end
    end

    assign debug_x10 = storage[10];
    assign debug_x31 = storage[31];

endmodule
