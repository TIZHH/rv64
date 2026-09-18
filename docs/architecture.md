# Architecture

## Current design

The current SC-00 design is a single SystemVerilog module named
`single_cycle_cpu`. It exposes a clock, synchronous active-high reset, and the
64-bit program counter for simulation visibility.

On a rising clock edge:

- reset sets the PC to zero;
- otherwise the PC advances by four bytes.

The Verilator C++ testbench drives reset and clock edges directly and checks the
observable PC after each cycle. This provides the build and simulation base for
SC-01, where instruction fetch, ADDI decode, a register file, immediate
generation, ALU addition, and writeback will be added.

## Planned structure

- `rtl/common/`: reusable datapath modules
- `rtl/single_cycle/`: single-cycle CPU integration
- `rtl/pipeline/`: future five-stage implementation
- `sim/verilator/`: Verilator testbench code
- `tests/asm/`: focused assembly tests added with instruction support

## Current limitations

No instructions, register file, memory model, or completion protocol exist yet.
The PC-only shell is solely the SC-00 clock/reset verification target.
