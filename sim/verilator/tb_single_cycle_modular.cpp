#include <array>
#include <cstdint>
#include <iostream>

#include "Vsingle_cycle_core.h"
#include "rv64i_tests.h"

namespace {

constexpr std::uint64_t kResultAddress = 0x100;

std::uint64_t read_word(const std::array<std::uint8_t, 4096>& memory,
                        std::uint64_t address) {
    const auto base = address & ~std::uint64_t{7};
    std::uint64_t value = 0;
    for (std::uint64_t lane = 0; lane < 8; lane++) {
        value |= static_cast<std::uint64_t>(memory[base + lane]) << (lane * 8);
    }
    return value;
}

void write_word(std::array<std::uint8_t, 4096>& memory, std::uint64_t address,
                std::uint64_t value, std::uint8_t mask) {
    const auto base = address & ~std::uint64_t{7};
    for (std::uint64_t lane = 0; lane < 8; lane++) {
        if ((mask >> lane) & 1U) {
            memory[base + lane] = static_cast<std::uint8_t>(value >> (lane * 8));
        }
    }
}

bool run_test(const Test& test) {
    Vsingle_cycle_core dut;
    std::array<std::uint8_t, 4096> memory{};
    for (const auto& [address, value] : test.initial_memory) {
        memory[address] = value;
    }

    dut.reset = 1;
    dut.instruction = 0;
    dut.data_read_data = 0;
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
    dut.reset = 0;

    for (int cycle = 0; cycle < 200; cycle++) {
        const auto pc = dut.pc;
        dut.instruction = (pc / 4 < test.program.size()) ? test.program[pc / 4] : 0;
        dut.clk = 0;
        dut.data_read_data = 0;
        dut.eval();
        dut.data_read_data = dut.data_read_enable ? read_word(memory, dut.data_address) : 0;
        dut.eval();

        const auto writes_memory = dut.data_write_enable;
        const auto write_address = dut.data_address;
        const auto write_data = dut.data_write_data;
        const auto write_mask = dut.data_write_mask;
        dut.clk = 1;
        dut.eval();

        if (writes_memory) {
            write_word(memory, write_address, write_data, write_mask);
            if (write_address == kResultAddress) {
                const auto actual = read_word(memory, kResultAddress);
                std::uint64_t expected_byte_mask = 0;
                if (test.expected_mask == 0xff) {
                    expected_byte_mask = ~std::uint64_t{0};
                } else {
                    for (std::uint64_t lane = 0; lane < 8; lane++) {
                        if ((test.expected_mask >> lane) & 1U) {
                            expected_byte_mask |= std::uint64_t{0xff} << (lane * 8);
                        }
                    }
                }
                const bool passed = write_mask == test.expected_mask &&
                                    (actual & expected_byte_mask) ==
                                        (test.expected & expected_byte_mask);
                if (!passed) {
                    std::cerr << "FAIL: " << test.name << "\n";
                }
                dut.final();
                return passed;
            }
        }
    }

    std::cerr << "FAIL: " << test.name << ": timeout\n";
    dut.final();
    return false;
}

bool run_illegal_test() {
    Vsingle_cycle_core dut;
    dut.reset = 1;
    dut.instruction = 0;
    dut.data_read_data = 0;
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
    dut.reset = 0;
    dut.instruction = 0xffffffffU;
    dut.clk = 0;
    dut.eval();
    const bool visible = dut.illegal_instruction;
    dut.clk = 1;
    dut.eval();
    const bool advances = dut.pc == 4;
    dut.final();
    return visible && advances;
}

}

int main() {
    bool all_passed = true;
    for (const auto& test : make_tests()) {
        all_passed = run_test(test) && all_passed;
    }
    all_passed = run_illegal_test() && all_passed;
    if (all_passed) {
        std::cout << "PASS: modular single-cycle RV64I tests\n";
        return 0;
    }
    return 1;
}
