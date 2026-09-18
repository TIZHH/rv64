#include "rv64i_tests.h"

namespace {

constexpr std::uint32_t kOpImm = 0x13;
constexpr std::uint32_t kOpAuipc = 0x17;
constexpr std::uint32_t kOpLoad = 0x03;
constexpr std::uint32_t kOpStore = 0x23;
constexpr std::uint32_t kOpReg = 0x33;
constexpr std::uint32_t kOpLui = 0x37;
constexpr std::uint32_t kOpBranch = 0x63;
constexpr std::uint32_t kOpJalr = 0x67;
constexpr std::uint32_t kOpJal = 0x6f;
constexpr std::uint32_t kOpImmW = 0x1b;
constexpr std::uint32_t kOpRegW = 0x3b;

std::uint32_t r_type(std::uint32_t funct7, std::uint32_t rs2,
                     std::uint32_t rs1, std::uint32_t funct3,
                     std::uint32_t rd, std::uint32_t opcode) {
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) |
           (rd << 7) | opcode;
}

std::uint32_t i_type(std::int32_t immediate, std::uint32_t rs1,
                     std::uint32_t funct3, std::uint32_t rd,
                     std::uint32_t opcode) {
    return (static_cast<std::uint32_t>(immediate) & 0xfffU) << 20 |
           (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode;
}

std::uint32_t s_type(std::int32_t immediate, std::uint32_t rs2,
                     std::uint32_t rs1, std::uint32_t funct3) {
    const auto encoded = static_cast<std::uint32_t>(immediate) & 0xfffU;
    return ((encoded >> 5) << 25) | (rs2 << 20) | (rs1 << 15) |
           (funct3 << 12) | ((encoded & 0x1fU) << 7) | kOpStore;
}

std::uint32_t b_type(std::int32_t immediate, std::uint32_t rs2,
                     std::uint32_t rs1, std::uint32_t funct3) {
    const auto encoded = static_cast<std::uint32_t>(immediate) & 0x1fffU;
    return (((encoded >> 12) & 1U) << 31) | (((encoded >> 5) & 0x3fU) << 25) |
           (rs2 << 20) | (rs1 << 15) | (funct3 << 12) |
           (((encoded >> 1) & 0xfU) << 8) | (((encoded >> 11) & 1U) << 7) |
           kOpBranch;
}

std::uint32_t u_type(std::uint32_t immediate, std::uint32_t rd,
                     std::uint32_t opcode) {
    return (immediate & 0xfffff000U) | (rd << 7) | opcode;
}

std::uint32_t j_type(std::int32_t immediate, std::uint32_t rd) {
    const auto encoded = static_cast<std::uint32_t>(immediate) & 0x1fffffU;
    return (((encoded >> 20) & 1U) << 31) | (((encoded >> 12) & 0xffU) << 12) |
           (((encoded >> 11) & 1U) << 20) | (((encoded >> 1) & 0x3ffU) << 21) |
           (rd << 7) | kOpJal;
}

std::uint32_t addi(std::uint32_t rd, std::uint32_t rs1, std::int32_t value) {
    return i_type(value, rs1, 0, rd, kOpImm);
}

std::vector<std::uint32_t> finish(std::vector<std::uint32_t> program) {
    program.push_back(s_type(0x100, 31, 0, 3));
    return program;
}

}

std::vector<Test> make_tests() {
    const auto negative_byte = std::vector<std::pair<std::uint64_t, std::uint8_t>>{{0x80, 0x80}};
    return {
        {"addi", finish({addi(1, 0, 12), addi(31, 1, -5)}), 7, 0xff, {}},
        {"addi_negative", finish({addi(31, 0, -1)}), ~std::uint64_t{0}, 0xff, {}},
        {"add", finish({addi(1, 0, 7), addi(2, 0, 5), r_type(0, 2, 1, 0, 31, kOpReg)}), 12, 0xff, {}},
        {"sub", finish({addi(1, 0, 7), addi(2, 0, 5), r_type(0x20, 2, 1, 0, 31, kOpReg)}), 2, 0xff, {}},
        {"sll", finish({addi(1, 0, 3), addi(2, 0, 4), r_type(0, 2, 1, 1, 31, kOpReg)}), 48, 0xff, {}},
        {"slt", finish({addi(1, 0, -1), addi(2, 0, 1), r_type(0, 2, 1, 2, 31, kOpReg)}), 1, 0xff, {}},
        {"sltu", finish({addi(1, 0, 1), addi(2, 0, -1), r_type(0, 2, 1, 3, 31, kOpReg)}), 1, 0xff, {}},
        {"xor", finish({addi(1, 0, 0x55), addi(2, 0, 0x0f), r_type(0, 2, 1, 4, 31, kOpReg)}), 0x5a, 0xff, {}},
        {"srl", finish({addi(1, 0, 0x40), addi(2, 0, 2), r_type(0, 2, 1, 5, 31, kOpReg)}), 0x10, 0xff, {}},
        {"sra", finish({addi(1, 0, -8), addi(2, 0, 1), r_type(0x20, 2, 1, 5, 31, kOpReg)}), ~std::uint64_t{3}, 0xff, {}},
        {"or", finish({addi(1, 0, 0x50), addi(2, 0, 0x0f), r_type(0, 2, 1, 6, 31, kOpReg)}), 0x5f, 0xff, {}},
        {"and", finish({addi(1, 0, 0x5f), addi(2, 0, 0x0f), r_type(0, 2, 1, 7, 31, kOpReg)}), 0x0f, 0xff, {}},
        {"slti", finish({addi(1, 0, -1), i_type(0, 1, 2, 31, kOpImm)}), 1, 0xff, {}},
        {"sltiu", finish({addi(1, 0, 1), i_type(-1, 1, 3, 31, kOpImm)}), 1, 0xff, {}},
        {"xori", finish({addi(1, 0, 0x55), i_type(0x0f, 1, 4, 31, kOpImm)}), 0x5a, 0xff, {}},
        {"ori", finish({addi(1, 0, 0x50), i_type(0x0f, 1, 6, 31, kOpImm)}), 0x5f, 0xff, {}},
        {"andi", finish({addi(1, 0, 0x5f), i_type(0x0f, 1, 7, 31, kOpImm)}), 0x0f, 0xff, {}},
        {"slli", finish({addi(1, 0, 3), i_type(4, 1, 1, 31, kOpImm)}), 48, 0xff, {}},
        {"srli", finish({addi(1, 0, 0x40), i_type(2, 1, 5, 31, kOpImm)}), 0x10, 0xff, {}},
        {"srai", finish({addi(1, 0, -8), i_type(0x401, 1, 5, 31, kOpImm)}), ~std::uint64_t{3}, 0xff, {}},
        {"lui", finish({u_type(0x12345000, 31, kOpLui)}), 0x12345000, 0xff, {}},
        {"auipc", finish({u_type(0x12345000, 31, kOpAuipc)}), 0x12345000, 0xff, {}},
        {"lb_sign", finish({addi(1, 0, 0x80), i_type(0, 1, 0, 31, kOpLoad)}), ~std::uint64_t{0x7f}, 0xff, negative_byte},
        {"lbu_zero", finish({addi(1, 0, 0x80), i_type(0, 1, 4, 31, kOpLoad)}), 0x80, 0xff, negative_byte},
        {"lh_sign", finish({addi(1, 0, 0x80), i_type(0, 1, 1, 31, kOpLoad)}), ~std::uint64_t{0x7fff}, 0xff, {{0x80, 0x00}, {0x81, 0x80}}},
        {"lhU_zero", finish({addi(1, 0, 0x80), i_type(0, 1, 5, 31, kOpLoad)}), 0x8000, 0xff, {{0x80, 0x00}, {0x81, 0x80}}},
        {"lw_sign", finish({addi(1, 0, 0x80), i_type(0, 1, 2, 31, kOpLoad)}), 0xffffffff80000000ULL, 0xff, {{0x80, 0x00}, {0x81, 0x00}, {0x82, 0x00}, {0x83, 0x80}}},
        {"lwu_zero", finish({addi(1, 0, 0x80), i_type(0, 1, 6, 31, kOpLoad)}), 0x80000000, 0xff, {{0x80, 0x00}, {0x81, 0x00}, {0x82, 0x00}, {0x83, 0x80}}},
        {"ld", finish({addi(1, 0, 0x80), i_type(0, 1, 3, 31, kOpLoad)}), 0x8877665544332211ULL, 0xff, {{0x80, 0x11}, {0x81, 0x22}, {0x82, 0x33}, {0x83, 0x44}, {0x84, 0x55}, {0x85, 0x66}, {0x86, 0x77}, {0x87, 0x88}}},
        {"jal", {j_type(8, 1), addi(31, 0, 99), addi(31, 1, 0), s_type(0x100, 31, 0, 3)}, 4, 0xff, {}},
        {"jalr", {addi(1, 0, 12), i_type(0, 1, 0, 2, kOpJalr), addi(31, 0, 99), addi(31, 2, 0), s_type(0x100, 31, 0, 3)}, 8, 0xff, {}},
        {"beq_taken", {addi(1, 0, 1), addi(2, 0, 1), b_type(8, 2, 1, 0), addi(31, 0, 99), addi(31, 0, 7), s_type(0x100, 31, 0, 3)}, 7, 0xff, {}},
        {"bne_taken", {addi(1, 0, 1), addi(2, 0, 2), b_type(8, 2, 1, 1), addi(31, 0, 99), addi(31, 0, 7), s_type(0x100, 31, 0, 3)}, 7, 0xff, {}},
        {"blt_taken", {addi(1, 0, -1), addi(2, 0, 1), b_type(8, 2, 1, 4), addi(31, 0, 99), addi(31, 0, 7), s_type(0x100, 31, 0, 3)}, 7, 0xff, {}},
        {"bge_taken", {addi(1, 0, 1), addi(2, 0, 1), b_type(8, 2, 1, 5), addi(31, 0, 99), addi(31, 0, 7), s_type(0x100, 31, 0, 3)}, 7, 0xff, {}},
        {"bltu_taken", {addi(1, 0, 1), addi(2, 0, -1), b_type(8, 2, 1, 6), addi(31, 0, 99), addi(31, 0, 7), s_type(0x100, 31, 0, 3)}, 7, 0xff, {}},
        {"bgeu_taken", {addi(1, 0, -1), addi(2, 0, 1), b_type(8, 2, 1, 7), addi(31, 0, 99), addi(31, 0, 7), s_type(0x100, 31, 0, 3)}, 7, 0xff, {}},
        {"sb", finish({addi(1, 0, 0x7f), s_type(0x100, 1, 0, 0)}), 0x7f, 1, {}},
        {"sh", finish({addi(1, 0, 0x123), s_type(0x100, 1, 0, 1)}), 0x123, 3, {}},
        {"sw", finish({u_type(0x12345000, 1, kOpLui), addi(1, 1, 0x678), s_type(0x100, 1, 0, 2)}), 0x12345678, 0xf, {}},
        {"sd", finish({u_type(0x12345000, 1, kOpLui), addi(1, 1, 0x678), s_type(0x100, 1, 0, 3)}), 0x12345678, 0xff, {}},
        {"addiw", finish({u_type(0x80000000, 1, kOpLui), i_type(1, 1, 0, 31, kOpImmW)}), 0xffffffff80000001ULL, 0xff, {}},
        {"slliw", finish({addi(1, 0, 1), i_type(4, 1, 1, 31, kOpImmW)}), 16, 0xff, {}},
        {"srliw", finish({u_type(0x80000000, 1, kOpLui), i_type(1, 1, 5, 31, kOpImmW)}), 0x40000000, 0xff, {}},
        {"sraiw", finish({u_type(0x80000000, 1, kOpLui), i_type(0x401, 1, 5, 31, kOpImmW)}), 0xffffffffc0000000ULL, 0xff, {}},
        {"addw", finish({u_type(0x80000000, 1, kOpLui), addi(2, 0, 1), r_type(0, 2, 1, 0, 31, kOpRegW)}), 0xffffffff80000001ULL, 0xff, {}},
        {"subw", finish({u_type(0x80000000, 1, kOpLui), addi(2, 0, 1), r_type(0x20, 2, 1, 0, 31, kOpRegW)}), 0x7fffffff, 0xff, {}},
        {"sllw", finish({addi(1, 0, 1), addi(2, 0, 4), r_type(0, 2, 1, 1, 31, kOpRegW)}), 16, 0xff, {}},
        {"srlw", finish({u_type(0x80000000, 1, kOpLui), addi(2, 0, 1), r_type(0, 2, 1, 5, 31, kOpRegW)}), 0x40000000, 0xff, {}},
        {"sraw", finish({u_type(0x80000000, 1, kOpLui), addi(2, 0, 1), r_type(0x20, 2, 1, 5, 31, kOpRegW)}), 0xffffffffc0000000ULL, 0xff, {}},
    };
}
