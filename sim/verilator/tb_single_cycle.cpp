#include <cstdint>
#include <iostream>

#include "Vsingle_cycle_cpu.h"

namespace {

void tick(Vsingle_cycle_cpu& dut) {
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
}

bool expect_pc(const Vsingle_cycle_cpu& dut, std::uint64_t expected,
               const char* phase) {
    if (dut.pc == expected) {
        return true;
    }

    std::cerr << "FAIL: " << phase << ": expected pc=0x" << std::hex
              << expected << ", actual pc=0x" << dut.pc << std::dec << '\n';
    return false;
}

}

int main() {
    Vsingle_cycle_cpu dut;

    dut.reset = 1;
    tick(dut);
    if (!expect_pc(dut, 0, "reset")) {
        return 1;
    }

    dut.reset = 0;
    tick(dut);
    if (!expect_pc(dut, 4, "first cycle after reset")) {
        return 1;
    }

    tick(dut);
    if (!expect_pc(dut, 8, "second cycle after reset")) {
        return 1;
    }

    dut.final();
    std::cout << "PASS: reset sets pc to 0 and sequential cycles advance by 4\n";
    return 0;
}
