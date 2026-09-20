#include "Vpc_register.h"

#include <cstdint>
#include <iostream>

void tick(Vpc_register &dut) {
  dut.clk_i = 0;
  dut.eval();

  dut.clk_i = 1;
  dut.eval();
}

struct PcCase {
  const char *name;
  bool reset_i;
  std::uint64_t next_pc_i;
  std::uint64_t expected_pc_o;
};
constexpr PcCase cases[] = {
    {"reset", true, 0x12345678, 0x0},
    {"normal_1", false, 0x12345678, 0x12345678},
    {"normal_2", false, 0xABCDEF00, 0xABCDEF00},
};

bool run_case(Vpc_register &dut, const PcCase &tc) {
  dut.reset_i = tc.reset_i;
  dut.next_pc_i = tc.next_pc_i;

  tick(dut);

  if (dut.pc_o != tc.expected_pc_o) {
    std::cerr << "FAIL " << tc.name << ": expected=0x" << std::hex
              << tc.expected_pc_o << " actual=0x" << dut.pc_o << '\n';
    return false;
  }
  return true;
}

int main() {
  Vpc_register dut;
  bool all_passed = true;

  for (const auto &tc : cases) {
    all_passed = run_case(dut, tc) && all_passed;
  }

  dut.final();
  if (all_passed) {
    std::cout << "PASS: pc_register\n";
    return 0;
  }
  return 1;
}
