#include <array>
#include <cstddef>
#include <cstdint>
#include <iostream>
#include <iterator>

#include "Vsingle_cycle_core.h"

namespace {

constexpr std::uint64_t kResultAddress = 0x100;
constexpr std::size_t kMemoryBytes = 4096;
constexpr int kCycleLimit = 200;

struct MemoryByte {
  std::uint64_t address;
  std::uint8_t value;
};

struct InstructionTest {
  const char *name;
  const std::uint32_t *program;
  std::size_t instruction_count;
  std::uint64_t expected_value;
  std::uint8_t expected_mask;
  const MemoryByte *initial_memory;
  std::size_t initial_memory_count;
};

// Each program contains literal RV64I machine code. Most tests finish by
// executing `sd x31, 0x100(x0)`, encoded as 0x11f03023.
constexpr std::uint32_t kAddiProgram[] = {0x00c00093, 0xffb08f93, 0x11f03023};
constexpr std::uint32_t kAddiNegativeProgram[] = {0xfff00f93, 0x11f03023};

constexpr std::uint32_t kAddProgram[] = {0x00700093, 0x00500113, 0x00208fb3,
                                         0x11f03023};
constexpr std::uint32_t kSubProgram[] = {0x00700093, 0x00500113, 0x40208fb3,
                                         0x11f03023};
constexpr std::uint32_t kSllProgram[] = {0x00300093, 0x00400113, 0x00209fb3,
                                         0x11f03023};
constexpr std::uint32_t kSltProgram[] = {0xfff00093, 0x00100113, 0x0020afb3,
                                         0x11f03023};
constexpr std::uint32_t kSltuProgram[] = {0x00100093, 0xfff00113, 0x0020bfb3,
                                          0x11f03023};
constexpr std::uint32_t kXorProgram[] = {0x05500093, 0x00f00113, 0x0020cfb3,
                                         0x11f03023};
constexpr std::uint32_t kSrlProgram[] = {0x04000093, 0x00200113, 0x0020dfb3,
                                         0x11f03023};
constexpr std::uint32_t kSraProgram[] = {0xff800093, 0x00100113, 0x4020dfb3,
                                         0x11f03023};
constexpr std::uint32_t kOrProgram[] = {0x05000093, 0x00f00113, 0x0020efb3,
                                        0x11f03023};
constexpr std::uint32_t kAndProgram[] = {0x05f00093, 0x00f00113, 0x0020ffb3,
                                         0x11f03023};

constexpr std::uint32_t kSltiProgram[] = {0xfff00093, 0x0000af93, 0x11f03023};
constexpr std::uint32_t kSltiuProgram[] = {0x00100093, 0xfff0bf93, 0x11f03023};
constexpr std::uint32_t kXoriProgram[] = {0x05500093, 0x00f0cf93, 0x11f03023};
constexpr std::uint32_t kOriProgram[] = {0x05000093, 0x00f0ef93, 0x11f03023};
constexpr std::uint32_t kAndiProgram[] = {0x05f00093, 0x00f0ff93, 0x11f03023};
constexpr std::uint32_t kSlliProgram[] = {0x00300093, 0x00409f93, 0x11f03023};
constexpr std::uint32_t kSrliProgram[] = {0x04000093, 0x0020df93, 0x11f03023};
constexpr std::uint32_t kSraiProgram[] = {0xff800093, 0x4010df93, 0x11f03023};

constexpr std::uint32_t kLuiProgram[] = {0x12345fb7, 0x11f03023};
constexpr std::uint32_t kAuipcProgram[] = {0x12345f97, 0x11f03023};

constexpr std::uint32_t kLbProgram[] = {0x08000093, 0x00008f83, 0x11f03023};
constexpr std::uint32_t kLbuProgram[] = {0x08000093, 0x0000cf83, 0x11f03023};
constexpr std::uint32_t kLhProgram[] = {0x08000093, 0x00009f83, 0x11f03023};
constexpr std::uint32_t kLhuProgram[] = {0x08000093, 0x0000df83, 0x11f03023};
constexpr std::uint32_t kLwProgram[] = {0x08000093, 0x0000af83, 0x11f03023};
constexpr std::uint32_t kLwuProgram[] = {0x08000093, 0x0000ef83, 0x11f03023};
constexpr std::uint32_t kLdProgram[] = {0x08000093, 0x0000bf83, 0x11f03023};

constexpr std::uint32_t kJalProgram[] = {0x008000ef, 0x06300f93, 0x00008f93,
                                         0x11f03023};
constexpr std::uint32_t kJalrProgram[] = {0x00c00093, 0x00008167, 0x06300f93,
                                          0x00010f93, 0x11f03023};

constexpr std::uint32_t kBeqProgram[] = {0x00100093, 0x00100113, 0x00208463,
                                         0x06300f93, 0x00700f93, 0x11f03023};
constexpr std::uint32_t kBneProgram[] = {0x00100093, 0x00200113, 0x00209463,
                                         0x06300f93, 0x00700f93, 0x11f03023};
constexpr std::uint32_t kBltProgram[] = {0xfff00093, 0x00100113, 0x0020c463,
                                         0x06300f93, 0x00700f93, 0x11f03023};
constexpr std::uint32_t kBgeProgram[] = {0x00100093, 0x00100113, 0x0020d463,
                                         0x06300f93, 0x00700f93, 0x11f03023};
constexpr std::uint32_t kBltuProgram[] = {0x00100093, 0xfff00113, 0x0020e463,
                                          0x06300f93, 0x00700f93, 0x11f03023};
constexpr std::uint32_t kBgeuProgram[] = {0xfff00093, 0x00100113, 0x0020f463,
                                          0x06300f93, 0x00700f93, 0x11f03023};

constexpr std::uint32_t kSbProgram[] = {0x07f00093, 0x10100023, 0x11f03023};
constexpr std::uint32_t kShProgram[] = {0x12300093, 0x10101023, 0x11f03023};
constexpr std::uint32_t kSwProgram[] = {0x123450b7, 0x67808093, 0x10102023,
                                        0x11f03023};
constexpr std::uint32_t kSdProgram[] = {0x123450b7, 0x67808093, 0x10103023,
                                        0x11f03023};

constexpr std::uint32_t kAddiwProgram[] = {0x800000b7, 0x00108f9b, 0x11f03023};
constexpr std::uint32_t kSlliwProgram[] = {0x00100093, 0x00409f9b, 0x11f03023};
constexpr std::uint32_t kSrliwProgram[] = {0x800000b7, 0x0010df9b, 0x11f03023};
constexpr std::uint32_t kSraiwProgram[] = {0x800000b7, 0x4010df9b, 0x11f03023};
constexpr std::uint32_t kAddwProgram[] = {0x800000b7, 0x00100113, 0x00208fbb,
                                          0x11f03023};
constexpr std::uint32_t kSubwProgram[] = {0x800000b7, 0x00100113, 0x40208fbb,
                                          0x11f03023};
constexpr std::uint32_t kSllwProgram[] = {0x00100093, 0x00400113, 0x00209fbb,
                                          0x11f03023};
constexpr std::uint32_t kSrlwProgram[] = {0x800000b7, 0x00100113, 0x0020dfbb,
                                          0x11f03023};
constexpr std::uint32_t kSrawProgram[] = {0x800000b7, 0x00100113, 0x4020dfbb,
                                          0x11f03023};

constexpr MemoryByte kNegativeByte[] = {{0x80, 0x80}};
constexpr MemoryByte kNegativeHalf[] = {{0x80, 0x00}, {0x81, 0x80}};
constexpr MemoryByte kNegativeWord[] = {
    {0x80, 0x00}, {0x81, 0x00}, {0x82, 0x00}, {0x83, 0x80}};
constexpr MemoryByte kDoubleWord[] = {{0x80, 0x11}, {0x81, 0x22}, {0x82, 0x33},
                                      {0x83, 0x44}, {0x84, 0x55}, {0x85, 0x66},
                                      {0x86, 0x77}, {0x87, 0x88}};

constexpr InstructionTest kTests[] = {
    {"ADDI", kAddiProgram, std::size(kAddiProgram), 7, 0xff, nullptr, 0},
    {"ADDI negative", kAddiNegativeProgram, std::size(kAddiNegativeProgram),
     0xffffffffffffffffULL, 0xff, nullptr, 0},

    {"ADD", kAddProgram, std::size(kAddProgram), 12, 0xff, nullptr, 0},
    {"SUB", kSubProgram, std::size(kSubProgram), 2, 0xff, nullptr, 0},
    {"SLL", kSllProgram, std::size(kSllProgram), 48, 0xff, nullptr, 0},
    {"SLT", kSltProgram, std::size(kSltProgram), 1, 0xff, nullptr, 0},
    {"SLTU", kSltuProgram, std::size(kSltuProgram), 1, 0xff, nullptr, 0},
    {"XOR", kXorProgram, std::size(kXorProgram), 0x5a, 0xff, nullptr, 0},
    {"SRL", kSrlProgram, std::size(kSrlProgram), 0x10, 0xff, nullptr, 0},
    {"SRA", kSraProgram, std::size(kSraProgram), 0xfffffffffffffffcULL, 0xff,
     nullptr, 0},
    {"OR", kOrProgram, std::size(kOrProgram), 0x5f, 0xff, nullptr, 0},
    {"AND", kAndProgram, std::size(kAndProgram), 0x0f, 0xff, nullptr, 0},

    {"SLTI", kSltiProgram, std::size(kSltiProgram), 1, 0xff, nullptr, 0},
    {"SLTIU", kSltiuProgram, std::size(kSltiuProgram), 1, 0xff, nullptr, 0},
    {"XORI", kXoriProgram, std::size(kXoriProgram), 0x5a, 0xff, nullptr, 0},
    {"ORI", kOriProgram, std::size(kOriProgram), 0x5f, 0xff, nullptr, 0},
    {"ANDI", kAndiProgram, std::size(kAndiProgram), 0x0f, 0xff, nullptr, 0},
    {"SLLI", kSlliProgram, std::size(kSlliProgram), 48, 0xff, nullptr, 0},
    {"SRLI", kSrliProgram, std::size(kSrliProgram), 0x10, 0xff, nullptr, 0},
    {"SRAI", kSraiProgram, std::size(kSraiProgram), 0xfffffffffffffffcULL, 0xff,
     nullptr, 0},

    {"LUI", kLuiProgram, std::size(kLuiProgram), 0x12345000, 0xff, nullptr, 0},
    {"AUIPC", kAuipcProgram, std::size(kAuipcProgram), 0x12345000, 0xff,
     nullptr, 0},

    {"LB", kLbProgram, std::size(kLbProgram), 0xffffffffffffff80ULL, 0xff,
     kNegativeByte, std::size(kNegativeByte)},
    {"LBU", kLbuProgram, std::size(kLbuProgram), 0x80, 0xff, kNegativeByte,
     std::size(kNegativeByte)},
    {"LH", kLhProgram, std::size(kLhProgram), 0xffffffffffff8000ULL, 0xff,
     kNegativeHalf, std::size(kNegativeHalf)},
    {"LHU", kLhuProgram, std::size(kLhuProgram), 0x8000, 0xff, kNegativeHalf,
     std::size(kNegativeHalf)},
    {"LW", kLwProgram, std::size(kLwProgram), 0xffffffff80000000ULL, 0xff,
     kNegativeWord, std::size(kNegativeWord)},
    {"LWU", kLwuProgram, std::size(kLwuProgram), 0x80000000, 0xff,
     kNegativeWord, std::size(kNegativeWord)},
    {"LD", kLdProgram, std::size(kLdProgram), 0x8877665544332211ULL, 0xff,
     kDoubleWord, std::size(kDoubleWord)},

    {"JAL", kJalProgram, std::size(kJalProgram), 4, 0xff, nullptr, 0},
    {"JALR", kJalrProgram, std::size(kJalrProgram), 8, 0xff, nullptr, 0},

    {"BEQ", kBeqProgram, std::size(kBeqProgram), 7, 0xff, nullptr, 0},
    {"BNE", kBneProgram, std::size(kBneProgram), 7, 0xff, nullptr, 0},
    {"BLT", kBltProgram, std::size(kBltProgram), 7, 0xff, nullptr, 0},
    {"BGE", kBgeProgram, std::size(kBgeProgram), 7, 0xff, nullptr, 0},
    {"BLTU", kBltuProgram, std::size(kBltuProgram), 7, 0xff, nullptr, 0},
    {"BGEU", kBgeuProgram, std::size(kBgeuProgram), 7, 0xff, nullptr, 0},

    {"SB", kSbProgram, std::size(kSbProgram), 0x7f, 0x01, nullptr, 0},
    {"SH", kShProgram, std::size(kShProgram), 0x123, 0x03, nullptr, 0},
    {"SW", kSwProgram, std::size(kSwProgram), 0x12345678, 0x0f, nullptr, 0},
    {"SD", kSdProgram, std::size(kSdProgram), 0x12345678, 0xff, nullptr, 0},

    {"ADDIW", kAddiwProgram, std::size(kAddiwProgram), 0xffffffff80000001ULL,
     0xff, nullptr, 0},
    {"SLLIW", kSlliwProgram, std::size(kSlliwProgram), 0x10, 0xff, nullptr, 0},
    {"SRLIW", kSrliwProgram, std::size(kSrliwProgram), 0x40000000, 0xff,
     nullptr, 0},
    {"SRAIW", kSraiwProgram, std::size(kSraiwProgram), 0xffffffffc0000000ULL,
     0xff, nullptr, 0},
    {"ADDW", kAddwProgram, std::size(kAddwProgram), 0xffffffff80000001ULL, 0xff,
     nullptr, 0},
    {"SUBW", kSubwProgram, std::size(kSubwProgram), 0x7fffffff, 0xff, nullptr,
     0},
    {"SLLW", kSllwProgram, std::size(kSllwProgram), 0x10, 0xff, nullptr, 0},
    {"SRLW", kSrlwProgram, std::size(kSrlwProgram), 0x40000000, 0xff, nullptr,
     0},
    {"SRAW", kSrawProgram, std::size(kSrawProgram), 0xffffffffc0000000ULL, 0xff,
     nullptr, 0},
};

std::uint64_t read_word(const std::array<std::uint8_t, kMemoryBytes> &memory,
                        std::uint64_t address) {
  const auto base = address & ~std::uint64_t{7};
  std::uint64_t value = 0;
  for (std::uint64_t lane = 0; lane < 8; ++lane) {
    value |= static_cast<std::uint64_t>(memory[base + lane]) << (lane * 8);
  }
  return value;
}

void write_word(std::array<std::uint8_t, kMemoryBytes> &memory,
                std::uint64_t address, std::uint64_t value, std::uint8_t mask) {
  const auto base = address & ~std::uint64_t{7};
  for (std::uint64_t lane = 0; lane < 8; ++lane) {
    if (((mask >> lane) & 1U) != 0) {
      memory[base + lane] = static_cast<std::uint8_t>(value >> (lane * 8));
    }
  }
}

std::uint64_t expand_byte_mask(std::uint8_t mask) {
  std::uint64_t expanded = 0;
  for (std::uint64_t lane = 0; lane < 8; ++lane) {
    if (((mask >> lane) & 1U) != 0) {
      expanded |= std::uint64_t{0xff} << (lane * 8);
    }
  }
  return expanded;
}

void reset(Vsingle_cycle_core &dut) {
  dut.reset_i = 1;
  dut.instruction_i = 0;
  dut.data_read_data_i = 0;
  dut.clk_i = 0;
  dut.eval();
  dut.clk_i = 1;
  dut.eval();
  dut.reset_i = 0;
}

bool run_instruction_test(const InstructionTest &test) {
  Vsingle_cycle_core dut;
  std::array<std::uint8_t, kMemoryBytes> memory{};
  for (std::size_t index = 0; index < test.initial_memory_count; ++index) {
    const auto &entry = test.initial_memory[index];
    memory[entry.address] = entry.value;
  }

  reset(dut);

  for (int cycle = 0; cycle < kCycleLimit; ++cycle) {
    const auto instruction_index = static_cast<std::size_t>(dut.pc_o / 4);
    dut.instruction_i = instruction_index < test.instruction_count
                            ? test.program[instruction_index]
                            : 0;

    dut.clk_i = 0;
    dut.data_read_data_i = 0;
    dut.eval();
    if (dut.data_read_enable_o) {
      dut.data_read_data_i = read_word(memory, dut.data_address_o);
      dut.eval();
    }

    const bool writes_memory = dut.data_write_enable_o;
    const auto write_address = dut.data_address_o;
    const auto write_data = dut.data_write_data_o;
    const auto write_mask = dut.data_write_mask_o;

    dut.clk_i = 1;
    dut.eval();

    if (!writes_memory) {
      continue;
    }

    write_word(memory, write_address, write_data, write_mask);
    if (write_address != kResultAddress) {
      continue;
    }

    const auto actual_value = read_word(memory, kResultAddress);
    const auto compared_bits = expand_byte_mask(test.expected_mask);
    const bool passed =
        write_mask == test.expected_mask &&
        (actual_value & compared_bits) == (test.expected_value & compared_bits);
    if (!passed) {
      std::cerr << "FAIL: " << test.name << " expected=0x" << std::hex
                << test.expected_value << " actual=0x" << actual_value
                << " expected_mask=0x"
                << static_cast<unsigned>(test.expected_mask)
                << " actual_mask=0x" << static_cast<unsigned>(write_mask)
                << std::dec << '\n';
    }
    dut.final();
    return passed;
  }

  std::cerr << "FAIL: " << test.name << " timeout pc=0x" << std::hex << dut.pc_o
            << std::dec << '\n';
  dut.final();
  return false;
}

bool run_illegal_instruction_test() {
  Vsingle_cycle_core dut;
  reset(dut);

  dut.instruction_i = 0xffffffffU;
  dut.clk_i = 0;
  dut.eval();
  const bool illegal_visible = dut.illegal_instruction_o;

  dut.clk_i = 1;
  dut.eval();
  const bool pc_advanced = dut.pc_o == 4;

  if (!illegal_visible || !pc_advanced) {
    std::cerr << "FAIL: illegal instruction visible=" << illegal_visible
              << " pc=0x" << std::hex << dut.pc_o << std::dec << '\n';
  }
  dut.final();
  return illegal_visible && pc_advanced;
}

} // namespace

int main() {
  bool all_passed = true;

  for (const auto &test : kTests) {
    const bool passed = run_instruction_test(test);
    if (passed) {
      std::cout << "PASS: " << test.name << '\n';
    }
    all_passed = passed && all_passed;
  }

  const bool illegal_passed = run_illegal_instruction_test();
  if (illegal_passed) {
    std::cout << "PASS: illegal instruction\n";
  }
  all_passed = illegal_passed && all_passed;

  if (!all_passed) {
    return 1;
  }

  std::cout << "PASS: all static modular single-cycle RV64I tests\n";
  return 0;
}
