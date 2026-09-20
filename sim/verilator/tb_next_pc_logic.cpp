#include "Vnext_pc_logic.h"

#include <cstdint>
#include <iostream>

struct NextPcCase {
  const char *name;

  std::uint64_t pc_i;
  std::uint64_t immediate_i;
  std::uint64_t register_a_i;

  bool branch_i;
  bool branch_taken_i;
  bool jump_i;
  bool jump_register_i;

  std::uint64_t expected_next_pc_o;
};

constexpr NextPcCase cases[] = {
    // 普通指令：PC + 4
    {
        "normal",
        0x1000,
        0,
        0,
        false,
        false,
        false,
        false,
        0x1004,
    },

    // branch 指令，但条件不成立
    {
        "branch_not_taken",
        0x1000,
        0x20,
        0,
        true,
        false,
        false,
        false,
        0x1004,
    },

    // branch 条件成立
    {
        "branch_taken",
        0x1000,
        0x20,
        0,
        true,
        true,
        false,
        false,
        0x1020,
    },

    // JAL：PC + immediate
    {
        "jal",
        0x1000,
        0x40,
        0,
        false,
        false,
        true,
        false,
        0x1040,
    },

    // JALR：register_a + immediate
    {
        "jalr",
        0x1000,
        0x20,
        0x2000,
        false,
        false,
        true,
        true,
        0x2020,
    },

    // JALR 结果最低 bit 必须清零
    {
        "jalr_clear_bit0",
        0x1000,
        0x01,
        0x2000,
        false,
        false,
        true,
        true,
        0x2000,
    },

    // jump 的优先级高于 branch
    {
        "jump_priority_over_branch",
        0x1000,
        0x20,
        0x2000,
        true,
        true,
        true,
        true,
        0x2020,
    },
};

bool run_case(Vnext_pc_logic &dut, const NextPcCase &tc) {
  dut.pc_i = tc.pc_i;
  dut.immediate_i = tc.immediate_i;
  dut.register_a_i = tc.register_a_i;

  dut.branch_i = tc.branch_i;
  dut.branch_taken_i = tc.branch_taken_i;
  dut.jump_i = tc.jump_i;
  dut.jump_register_i = tc.jump_register_i;

  dut.eval();

  if (dut.next_pc_o != tc.expected_next_pc_o) {
    std::cerr << "FAIL " << tc.name << ": expected=0x" << std::hex
              << tc.expected_next_pc_o << " actual=0x" << dut.next_pc_o << '\n';
    return false;
  }

  return true;
}

int main() {
  Vnext_pc_logic dut;
  bool all_passed = true;

  for (const auto &tc : cases) {
    all_passed = run_case(dut, tc) && all_passed;
  }

  dut.final();

  if (all_passed) {
    std::cout << "PASS: next_pc_logic\n";
    return 0;
  }

  return 1;
}