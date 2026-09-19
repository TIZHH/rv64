#include <cstdint>
#include <iostream>

#include "Vsingle_cycle_file_system.h"

int main() {
    Vsingle_cycle_file_system dut;
    dut.reset = 1;
    dut.clk = 0;
    dut.eval();
    dut.clk = 1;
    dut.eval();
    dut.reset = 0;

    for (int cycle = 0; cycle < 20; cycle++) {
        dut.clk = 0;
        dut.eval();
        dut.clk = 1;
        dut.eval();

        if (dut.debug_memory_word == 7) {
            std::cout << "PASS: file-backed instruction/data memory test\n";
            dut.final();
            return 0;
        }
    }

    std::cerr << "FAIL: file-backed memory result=0x" << std::hex
              << dut.debug_memory_word << " x31=0x" << dut.debug_x31
              << " pc=0x" << dut.pc << std::dec << '\n';
    dut.final();
    return 1;
}
