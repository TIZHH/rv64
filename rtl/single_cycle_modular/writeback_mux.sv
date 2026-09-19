module writeback_mux (
    input  logic [2:0]  source,
    input  logic [63:0] alu_result,
    input  logic [63:0] load_value,
    input  logic [63:0] pc,
    input  logic [63:0] immediate,
    output logic [63:0] writeback_data
);

    localparam logic [2:0] WB_ALU   = 3'd0;
    localparam logic [2:0] WB_LOAD  = 3'd1;
    localparam logic [2:0] WB_PC4   = 3'd2;
    localparam logic [2:0] WB_IMM   = 3'd3;
    localparam logic [2:0] WB_AUIPC = 3'd4;

    always_comb begin
        case (source)
            WB_ALU:   writeback_data = alu_result;
            WB_LOAD:  writeback_data = load_value;
            WB_PC4:   writeback_data = pc + 64'd4;
            WB_IMM:   writeback_data = immediate;
            WB_AUIPC: writeback_data = pc + immediate;
            default:  writeback_data = alu_result;
        endcase
    end

endmodule
