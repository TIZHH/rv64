module writeback_mux (
    input  logic [2:0]  source_i,
    input  logic [63:0] alu_result_i,
    input  logic [63:0] load_value_i,
    input  logic [63:0] pc_i,
    input  logic [63:0] immediate_i,
    output logic [63:0] writeback_data_o
);

    localparam logic [2:0] WB_ALU   = 3'd0;
    localparam logic [2:0] WB_LOAD  = 3'd1;
    localparam logic [2:0] WB_PC4   = 3'd2;
    localparam logic [2:0] WB_IMM   = 3'd3;
    localparam logic [2:0] WB_AUIPC = 3'd4;

    always_comb begin
        case (source_i)
            WB_ALU:   writeback_data_o = alu_result_i;
            WB_LOAD:  writeback_data_o = load_value_i;
            WB_PC4:   writeback_data_o = pc_i + 64'd4;
            WB_IMM:   writeback_data_o = immediate_i;
            WB_AUIPC: writeback_data_o = pc_i + immediate_i;
            default:  writeback_data_o = alu_result_i;
        endcase
    end

endmodule
