#include <array>
#include <cstdint>
#include <iostream>
#include <string_view>

#include "Vbranch_unit.h"

using std::array;
using std::string_view;
using std::uint64_t;

struct BranchCase {
  std::string_view name;
  std::uint8_t branch_type;
  std::uint64_t left;
  std::uint64_t right;
  bool expected_taken;
};

constexpr std::array<BranchCase, 13> kCases{{
    {"beq_equal", 0b000, 42, 42, true},
    {"beq_not_equal", 0b000, 42, 7, false},

    {"bne_not_equal", 0b001, 42, 7, true},
    {"bne_equal", 0b001, 42, 42, false},

    // 0xffffffffffffffff 按 signed 解释就是 -1
    {"blt_signed_negative", 0b100, 0xffffffffffffffffULL, 1, true},
    {"blt_signed_false", 0b100, 1, 0xffffffffffffffffULL, false},

    {"bge_signed_equal", 0b101, 7, 7, true},
    {"bge_signed_negative", 0b101, 0xffffffffffffffffULL, 1, false},

    // 按 unsigned 解释时，0xffffffffffffffff 是最大的 uint64_t
    {"bltu_unsigned", 0b110, 1, 0xffffffffffffffffULL, true},
    {"bltu_unsigned_false", 0b110, 0xffffffffffffffffULL, 1, false},

    {"bgeu_unsigned_equal", 0b111, 7, 7, true},
    {"bgeu_unsigned", 0b111, 0xffffffffffffffffULL, 1, true},

    {"unsupported_type", 0b010, 0, 0, false},
}};

bool run_case(Vbranch_unit &dut, const BranchCase &test_case) {
  dut.branch_type_i = test_case.branch_type;
  dut.left_i = test_case.left;
  dut.right_i = test_case.right;
  dut.eval();

  const bool actual_taken = dut.taken_o;
  if (actual_taken == test_case.expected_taken) {
    return true;
  }

  std::cerr << "FAIL: " << test_case.name << ": branch_type=0x" << std::hex
            << static_cast<unsigned>(test_case.branch_type) << " left=0x"
            << test_case.left << " right=0x" << test_case.right << std::dec
            << " expected_taken=" << test_case.expected_taken
            << " actual_taken=" << actual_taken << '\n';
  return false;
}

int main() {
  Vbranch_unit dut;
  bool all_passed = true;

  for (const auto &test_case : kCases) {
    all_passed = run_case(dut, test_case) && all_passed;
  }

  dut.final();
  if (all_passed) {
    std::cout << "PASS: branch_unit truth table\n";
    return 0;
  }
  return 1;
}
