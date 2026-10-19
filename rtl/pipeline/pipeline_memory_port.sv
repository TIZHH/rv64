
module pipeline_memory_port (
    // 当前 MEM 阶段里的指令是否有效
    input  logic        valid_i,

    // 当前指令是否需要读内存
    input  logic        read_enable_i,

    // 当前指令是否需要写内存
    input  logic        write_enable_i,

    // EX 阶段已经算好的访存地址
    input  logic [63:0] address_i,

    // Store 指令要写入内存的数据
    input  logic [63:0] store_data_i,

    // 访存大小
    // 0 = 1 byte
    // 1 = 2 bytes
    // 2 = 4 bytes
    // 3 = 8 bytes
    input  logic [2:0]  memory_size_i,

    // 输出给外部 Data Memory
    output logic [63:0] data_address_o,
    output logic        data_read_enable_o,
    output logic [63:0] data_write_data_o,
    output logic [7:0]  data_write_mask_o,
    output logic        data_write_enable_o
);

    always_comb begin

        // 地址直接传给 Data Memory
        data_address_o = address_i;

        // 只有当前流水线指令有效时，才能真的发起读写
        data_read_enable_o  = valid_i && read_enable_i;
        data_write_enable_o = valid_i && write_enable_i;

        // 根据地址最低 3 bit，把 store 数据移动到正确 byte lane
        data_write_data_o =
            store_data_i << (address_i[2:0] * 8);

        // 默认不写任何 byte
        data_write_mask_o = 8'd0;

        // Store 时根据 memory_size 生成 byte mask
        if (data_write_enable_o) begin
            case (memory_size_i)

                // SB：写 1 byte
                3'd0:
                    data_write_mask_o =
                        8'b00000001 << address_i[2:0];

                // SH：写 2 bytes
                3'd1:
                    data_write_mask_o =
                        8'b00000011 << address_i[2:0];

                // SW：写 4 bytes
                3'd2:
                    data_write_mask_o =
                        8'b00001111 << address_i[2:0];

                // SD：写 8 bytes
                3'd3:
                    data_write_mask_o =
                        8'b11111111;

                default:
                    data_write_mask_o = 8'd0;
            endcase
        end
    end

endmodule
